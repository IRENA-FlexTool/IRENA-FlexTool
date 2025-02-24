import time
import csv
import math
import subprocess
import logging
import copy
import sys
import os
import xml.etree.ElementTree as ET
import pandas as pd
import shutil
import spinedb_api as api
from spinedb_api import DatabaseMapping
# from spinedb_api.filters.scenario_filter import scenario_filter_config, scenario_filter_from_dict
from pathlib import Path
from collections import OrderedDict
from collections import defaultdict


#return_codes
#0 : Success
#-1: Failure (Defined in the Toolbox)
#1: Infeasible or unbounded problem (not implemented in the toolbox, functionally same as -1. For a possiblity of a graphical depiction)


class FlexToolRunner:
    """
    Define Class to run the model and read and recreate the required config files:
    """

    def __init__(self, input_db_url=None, scenario_name=None, flextool_dir=None, bin_dir=None, root_dir=None):
        self.logger = logging.getLogger(__name__)
#        logger.basicConfig(
#            stream=sys.stderr,
#            level=logging.DEBUG,
#            format='%(asctime)s %(levelname)s: %(message)s',
#            datefmt='%Y-%m-%d %H:%M:%S',
#        )
        translation = {39: None}
        # delete highs.log from previous run
        if os.path.exists("./HiGHS.log"):
            os.remove("./HiGHS.log")
        # make a directory for model unit tests
        if not os.path.exists("./tests"):
            os.makedirs("./tests")
        if flextool_dir is None:
            self.flextool_dir = Path(__file__).parent.parent / "flextool"
        if bin_dir is None:
            self.bin_dir = Path(__file__).parent.parent / "bin"
        if root_dir is None:
            self.root_dir = Path(__file__).parent.parent
        print(str(self.root_dir))
        # read the data in
        # open connection to input db
        if scenario_name:
            scen_config = api.filters.scenario_filter.scenario_filter_config(scenario_name)
        with (DatabaseMapping(input_db_url) as db):
            if scenario_name:
                api.filters.scenario_filter.scenario_filter_from_dict(db, scen_config)
            self.check_version(db=db)
            self.timelines = self.params_to_dict(db=db, cl="timeline", par="timestep_duration", mode="defaultdict")
            self.model_solve = self.params_to_dict(db=db, cl="model", par="solves", mode="defaultdict")
            self.solve_modes = self.params_to_dict(db=db, cl="solve", par="solve_mode", mode="dict")
            self.roll_counter = self.make_roll_counter()
            self.highs_presolve = self.params_to_dict(db=db, cl="solve", par="highs_presolve", mode="dict")
            self.highs_method = self.params_to_dict(db=db, cl="solve", par="highs_method", mode="dict")
            self.highs_parallel = self.params_to_dict(db=db, cl="solve", par="highs_parallel", mode="dict")
            self.solve_period_years_represented = self.params_to_dict(db=db, cl="solve", par="years_represented", mode="defaultdict")
            self.solvers = self.params_to_dict(db=db, cl="solve", par="solver", mode="dict")
            self.timeblocks = self.params_to_dict(db=db, cl="timeblockSet", par="block_duration", mode="defaultdict")
            self.timeblocks__timeline = self.entities_to_dict(db=db, cl="timeblockSet__timeline", mode="defaultdict")
            self.stochastic_branches = self.params_to_dict(db=db, cl="solve", par="stochastic_branches", mode="defaultdict")
            self.solver_precommand = self.params_to_dict(db=db, cl="solve", par="solver_precommand", mode="dict")
            self.solver_arguments = self.params_to_dict(db=db, cl="solve", par="solver_arguments", mode="defaultdict")
            self.contains_solves = self.params_to_dict(db=db, cl="solve", par="contains_solves", mode="defaultdict", str_to_list=True)
            self.hole_multipliers = self.params_to_dict(db=db, cl="solve", par="timeline_hole_multiplier", mode="defaultdict")
            self.new_step_durations = self.params_to_dict(db=db, cl="timeblockSet", par="new_stepduration", mode="dict")
            # Rolling parameter is packaged from three parameters
            rolling_duration = self.params_to_dict(db=db, cl="solve", par="rolling_duration", mode="dict")
            rolling_solve_horizon = self.params_to_dict(db=db, cl="solve", par="rolling_solve_horizon", mode="dict")
            rolling_solve_jump = self.params_to_dict(db=db, cl="solve", par="rolling_solve_jump", mode="dict")
            self.rolling_times = defaultdict(list)
            all_keys = list(set(rolling_duration) | set(rolling_solve_horizon) | set(rolling_solve_jump))
            for i, var in enumerate([rolling_solve_jump, rolling_solve_horizon, rolling_duration]):
                for key in all_keys:
                    if key in var:
                        self.rolling_times[key].append(var[key])
                    else:
                        if i == 0:
                            self.rolling_times[key].append(0)
                        if i == 1:
                            self.rolling_times[key].append(0)
                        if i == 2:
                            self.rolling_times[key].append(-1)  # If rolling_duration is not given, assume -1
            self.timeblocks_used_by_solves = self.get_period_timesets(db=db)

            self.invest_periods = self.periods_to_tuples(db=db, cl="solve", par="invest_periods")
            self.realized_periods = self.periods_to_tuples(db=db, cl="solve", par="realized_periods")
            self.realized_invest_periods = self.periods_to_tuples(db=db, cl="solve", par="realized_invest_periods")
            self.fix_storage_periods = self.periods_to_tuples(db=db, cl="solve", par="fix_storage_periods")


        self.stochastic_timesteps = defaultdict(list)
        self.original_timeline = defaultdict()
        self.create_timeline_from_timestep_duration()
        self.first_of_complete_solve = []
        self.last_of_solve = []
        #self.write_full_timelines(self.timelines, 'steps.csv')


    def periods_to_tuples(self, db, cl, par):
        entities = db.get_entity_items(entity_class_name=cl)
        params = db.get_parameter_value_items(entity_class_name=cl,
                                                 parameter_definition_name=par)
        tuple_list = []
        for entity in entities:
            params = db.get_parameter_value_items(entity_class_name=cl,
                                                  entity_name=entity["name"],
                                                  parameter_definition_name=par)
            for param in params:
                param_value = api.from_database(param["value"], param["type"])

                for (i, row) in enumerate(param_value.values):
                    if isinstance(param_value.values[i], api.Map):
                        new_name = param["entity_name"] + "_" + param_value.indexes[i]
                        self.duplicate_solve(param["entity_name"], new_name)
                        tuple_list.append((new_name, param_value.indexes[i]))

                        new_period_timeblockset_list = []
                        for solve, period__timeblockset_list in list(self.timeblocks_used_by_solves.items()):
                            if solve == param["entity_name"]:
                                for period__timeblockset in period__timeblockset_list:
                                    if period__timeblockset[0] == param_value.indexes[i]:
                                        new_period_timeblockset_list.append(period__timeblockset)
                        if new_name not in self.timeblocks_used_by_solves.keys():
                            self.timeblocks_used_by_solves[new_name] = new_period_timeblockset_list
                        else:
                            for item in new_period_timeblockset_list:
                                if item not in self.timeblocks_used_by_solves[new_name]:
                                    self.timeblocks_used_by_solves[new_name].append(item)
                    else:
                        tuple_list.append((param["entity_name"], row))
        return tuple_list



    def get_period_timesets(self, db):
        entities = db.get_entity_items(entity_class_name="solve")
        params = db.get_parameter_value_items(entity_class_name="solve",
                                                 parameter_definition_name="period_timeblockSet")
        timeblocks_used_by_solves = defaultdict(list)

        solves_in_model = [item for sublist in
                           list(self.model_solve.values()) + list(self.contains_solves.values()) for item in sublist]
        for entity in entities:
            if entity["name"] in solves_in_model:
                params = db.get_parameter_value_items(entity_class_name="solve",
                                                      entity_name=entity["name"],
                                                      parameter_definition_name="period_timeblockSet")
                for param in params:
                    param_value = api.from_database(param["value"], param["type"])
                    for (i, row) in enumerate(param_value.indexes):
                        if isinstance(param_value.values[i], api.Map):
                            new_name = param["entity_name"] + "_" + param_value.indexes[i]
                            self.duplicate_solve(param["entity_name"], new_name)
                            timeblocks_used_by_solves[new_name].append((param_value.values[i].indexes[i],
                                                                        param_value.values[i].values[i]))
                        else:
                            timeblocks_used_by_solves[param["entity_name"]].append((param_value.indexes[i],
                                                                                param_value.values[i]))
        return timeblocks_used_by_solves



    def check_version(self, db):
        db_version_item = db.get_parameter_definition_item(entity_class_name="model",
                                                           name="version")
        if not db_version_item:
            self.logger.error("No version information found in the FlexTool input database, check you have a correct database.")
            sys.exit(-1)
        database_version = api.from_database(db_version_item["default_value"], db_version_item["default_type"])
        tool_version = 22.0
        if float(database_version) < tool_version:
            self.logger.error(
                "The input database is in an older version than the tool. Please migrate the database to the new version: python migrate_database.py path_to_database")
            sys.exit(-1)



    def duplicate_solve(self, old_solve, new_name):
        if new_name not in self.model_solve.values() and new_name not in self.contains_solves.values():
            dup_map_list=[
                self.solve_modes,
                self.roll_counter,
                self.highs_presolve,
                self.highs_method,
                self.highs_parallel,
                self.solve_period_years_represented,
                self.solvers,
                self.solver_precommand,
                self.solver_arguments,
                self.contains_solves,
                self.rolling_times
            ]
            for dup_map in dup_map_list:
                if old_solve in dup_map.keys():
                    dup_map[new_name]=dup_map[old_solve]
            for model, solves in list(self.model_solve.items()):
                if old_solve in solves:
                    solves.remove(old_solve)
                if new_name not in solves:
                    solves.append(new_name)
                self.model_solve[model] = solves


    def make_roll_counter(self):
        roll_counter_map={}
        for key, mode in list(self.solve_modes.items()):
            if mode == "rolling_window":
                roll_counter_map[key] = 0
        return roll_counter_map


    def create_timeline_from_timestep_duration(self):
        for timeblockSet_name, timeblockSet in list(self.timeblocks.items()):
            if timeblockSet_name in self.new_step_durations.keys():
                step_duration= float(self.new_step_durations[timeblockSet_name])
                #create the new timeline
                timeline_name = self.timeblocks__timeline[timeblockSet_name][0]
                old_steps = self.timelines[timeline_name]
                new_steps = []
                new_timeblocks = []
                for timeblock in timeblockSet:
                    first_step = timeblock[0]
                    first_index = [step[0] for step in old_steps].index(timeblock[0])
                    step_counter = 0 #float(old_steps[first_index][1])
                    last_index = first_index + int(float(timeblock[1]))
                    added_steps = 0
                    for step in old_steps[first_index:last_index]:
                        if step_counter >= step_duration:
                            new_steps.append((first_step,str(step_counter)))
                            first_step = step[0]
                            step_counter=0
                            added_steps += 1
                            if step_counter> step_duration:
                                self.logger.warning("Warning: All new steps are not the size of the given step duration. The new step duration has to be multiple of old step durations for this to happen.")
                        step_counter += float(step[1])
                    new_steps.append((first_step,str(step_counter)))
                    added_steps += 1
                    new_timeblocks.append((timeblock[0], added_steps))
                self.timeblocks[timeblockSet_name] = new_timeblocks 
                new_timeline_name = timeline_name+ "_"+ timeblockSet_name 
                self.timelines[new_timeline_name] = new_steps
                self.timeblocks__timeline[timeblockSet_name] = [new_timeline_name]
                self.original_timeline[new_timeline_name] = timeline_name

    def create_averaged_timeseries(self,solve):
        timeseries_map={
            'pt_node_inflow.csv': "sum",
            'pt_commodity.csv': "average",
            'pt_group.csv': "average",
            'pt_node.csv': "average",
            'pt_process.csv': "average",
            'pt_profile.csv': "average",
            'pt_process_source.csv': "average",
            'pt_process_sink.csv': "average",
            'pt_reserve__upDown__group.csv': "average",
            'pbt_node_inflow.csv': "sum",
            'pbt_node.csv': "average",
            'pbt_process.csv': "average",
            'pbt_profile.csv': "average",
            'pbt_process_source.csv': "average",
            'pbt_process_sink.csv': "average",
            'pbt_reserve__upDown__group.csv': "average"
        }
        create = False
        for period_timeblock in self.timeblocks_used_by_solves[solve]:
            if period_timeblock[1] in self.new_step_durations.keys():
                create = True
        if not create:    
            for timeseries in timeseries_map.keys():
                shutil.copy('input/'+timeseries,'solve_data/'+timeseries)
        else:
            timelines=[]
            for period, timeblockSet in self.timeblocks_used_by_solves[solve]:
                timeline = self.timeblocks__timeline[timeblockSet][0]
                if timeline not in timelines:
                    if len(timelines) != 0:
                        self.logger.error("Error: More than one timeline in the solve or the same timeline with different step durations in different timeblockSets")
                        sys.exit(-1)
                    timelines.append(timeline)
            for timeseries in timeseries_map.keys():
                with open('input/'+ timeseries,'r') as blk:
                    filereader = csv.reader(blk, delimiter=',')
                    with open('solve_data/'+timeseries,'w', newline='') as solve_file:
                        filewriter = csv.writer(solve_file,delimiter=',')
                        headers = next(filereader)
                        filewriter.writerow(headers)
                        #assumes that the data is in the format:
                        #[group1, group2, ... group_last, time, numeric_value]
                        #ie. the numeric data is the last column and the timestep is the one before it.
                        #and that there are no rows from other groups between the rows of one group 
                        time_index = headers.index('time')
                        while True:
                            try:
                                datain = next(filereader)
                                timeline_step_duration = None
                                for timeline in timelines:
                                    new_timeline = self.timelines[timeline]
                                    for timeline_row in new_timeline:
                                        if timeline_row[0] == datain[time_index]:
                                            timeline_step_duration = int(float(timeline_row[1]))
                                            break
                                if timeline_step_duration != None:
                                    values = []
                                    params = datain[0:time_index]
                                    row = datain[0:time_index + 1]
                                    values.append(float(datain[time_index + 1])),
                                    if datain[1] != 'storage_state_reference_value':
                                        for i in range(timeline_step_duration - 1):
                                            datain = next(filereader)
                                            if datain[0:time_index] != params:
                                                self.logger.error("Cannot find the same timesteps in input data as in timeline for file  " + timeseries + " after " + row[-1])
                                                sys.exit(-1)
                                            values.append(float(datain[time_index + 1]))

                                    if timeseries_map[timeseries] == "average":
                                        out_value = round(sum(values) / len(values), 6)
                                    else:
                                        out_value = sum(values)
                                    row.append(out_value)
                                    filewriter.writerow(row)
                                else:
                                    #find previous timestep that is included and add this to the list
                                    #this is for the parameters that do not have a value for each timestep
                                    if datain[1] == 'storage_state_reference_value':
                                        #get current index:
                                        counter = 0
                                        for timestep in self.timelines[self.original_timeline[timeline]]:
                                            if datain[2] == timestep[0]:
                                                current_index = counter 
                                            counter +=1
                                        found = False
                                        for timestep in reversed(self.timelines[self.original_timeline[timeline]][0:current_index+1]):
                                            for timeline_row in new_timeline:
                                                if timeline_row[0] == timestep[0]:
                                                    new_index = timeline_row[0]
                                                    found = True
                                                    break
                                            if found:
                                                break
                                        if found:
                                            row = datain[0:time_index]
                                            row.append(new_index)
                                            row.append(datain[time_index + 1])
                                            filewriter.writerow(row)
                            except Exception:
                                break
            #constaint inflow to a longer step size
            node__inflow = []
            with open('input/'+ 'p_node.csv','r') as blk:
                filereader = csv.reader(blk, delimiter=',')
                read_header = next(filereader)
                while True:
                    try:
                        datain = next(filereader)
                        if datain[1] == 'inflow':
                            node__inflow.append([datain[0],datain[2]])
                    except Exception:
                        break
            with open('solve_data/'+ 'pt_node_inflow.csv','a', newline='') as blk:
                filewriter = csv.writer(blk, delimiter=',')
                for timeline in timelines:
                    new_timeline = self.timelines[timeline]
                    for node__value in node__inflow:
                        for timeline_row in new_timeline:
                            timeline_step_duration = int(float(timeline_row[1]))
                            value = float(node__value[1])*timeline_step_duration
                            row = [node__value[0],timeline_row[0],value]
                            filewriter.writerow(row)


    def make_steps(self, start, stop):
        """
        make a list of timesteps available
        :param start: Start index of of the block
        :param stop: Stop index of the block
        :param steplist: list of steps, read from steps.csv
        :return: list of timesteps
        """

        active_step = start
        steps = []
        while active_step <= stop:
            steps.append(self.steplist[active_step])
            active_step += 1
        return steps

    def write_full_timelines(self, stochastic_timesteps, period__timeblocks_in_this_solve, timeblocks__timeline, timelines, filename):
        """
        write to file a list of timestep as defined in timelines.
        :param filename: filename to write to
        :param steplist: list of timestep indexes
        :return:
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period,step\n')
            for period__timeblock in period__timeblocks_in_this_solve:
                for timeline in timelines:
                    for timeblock_in_timeline, tt in timeblocks__timeline.items():
                        if period__timeblock[1] == timeblock_in_timeline:
                            if timeline == tt[0]:
                                for item in timelines[timeline]:
                                    outfile.write(period__timeblock[0] + ',' + item[0] + '\n')
            for step in stochastic_timesteps:
                outfile.write(step[0] + ',' + step[1] + '\n')

    def write_active_timelines(self, timeline, filename, complete = False):
        """
        write to file a list of timesteps as defined by the active timeline of the current solve
        :param filename: filename to write to
        :param timeline: list of tuples containing the period and the timestep
        :return: nothing
        """
        if not complete:
            with open(filename, 'w') as outfile:
                # prepend with a header
                outfile.write('period,step,step_duration\n')
                for period_name, period in timeline.items():
                    for item in period:
                        outfile.write(period_name + ',' + item[0] + ',' + str(item[2]) + '\n')
        else: 
            with open(filename, 'w') as outfile:
                # prepend with a header
                outfile.write('period,step,complete_step_duration\n')
                for period_name, period in timeline.items():
                    for item in period:
                        outfile.write(period_name + ',' + item[0] + ',' + str(item[2]) + '\n')

    def write_years_represented(self, period__branch, years_represented, filename):
        """
        write to file a list of periods with the number of years the period represents before the next period starts
        :param filename: filename to write to
        :param years_represented: dict of periods with the number of years represented
        :return: nothing
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period,years_from_solve,p_years_from_solve,p_years_represented\n')
            year_count = 0
            for period__years in years_represented:
                for i in range(int(max(1.0, float(period__years[1])))):
                    years_to_cover_within_year = min(1, float(period__years[1]))
                    outfile.write(period__years[0] + ',y' + str(year_count) + ',' + str(year_count) + ','
                            + str(years_to_cover_within_year) + '\n')
                    for pd in period__branch:
                        if pd[0] in period__years[0] and pd[0] != pd[1]:
                            outfile.write(pd[1]+ ',y' + str(year_count) + ',' + str(year_count) + ','
                            + str(years_to_cover_within_year) + '\n')
                    year_count = year_count + years_to_cover_within_year

    def write_hole_multiplier(self, solve, filename):
        with open(filename, 'w') as holefile:
            holefile.write("solve,p_hole_multiplier\n")
            if self.hole_multipliers[solve]:
                holefile.write(solve + "," + self.hole_multipliers[solve] + "\n")


    def write_period_years(self, stochastic_branches, years_represented, filename):
        """
        write to file a list of timesteps as defined by the active timeline of the current solve
        :param filename: filename to write to
        :param timeline: list of tuples containing the period and the timestep
        :return: nothing
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period,param\n')
            year_count = 0
            for period__year in years_represented:
                outfile.write(period__year[0] + ',' + str(year_count) + '\n')
                for pd in stochastic_branches:
                    if pd[0] in period__year[0] and pd[0] != pd[1]:
                        outfile.write(pd[1] + ',' + str(year_count) + '\n')
                year_count += float(period__year[1])


    def make_block_timeline(self, start, length):
        """
        make a block timeline, there might be multiple blocks per solve so these blocks might need to be combined for a run
        :param start: start of block
        :param length: length of block
        :return: block timeline
        """
        steplist = []
        startnum = self.steplist.index(start)
        for i in range(startnum, math.ceil(startnum + float(length))):
            steplist.append(self.steplist[i])
        return steplist

    def model_run(self, current_solve):
        """
        run the model executable once
        :return the output of glpsol:
        """
        try:
            solver = self.solvers[current_solve]
        except KeyError:
            self.logger.warning(f"No solver defined for {current_solve}. Defaulting to highs.")
            solver = "highs"
        if sys.platform.startswith("linux"):
            glpsol_file = str(self.bin_dir / "glpsol")
            highs_file = str(self.bin_dir / "highs")
            if os.path.exists(glpsol_file):
                current_permissions = os.stat(glpsol_file).st_mode & 0o777
                if current_permissions != 0o755:
                    os.chmod(glpsol_file, 0o755)
            if os.path.exists(highs_file):
                current_permissions = os.stat(highs_file).st_mode & 0o777
                if current_permissions != 0o755:
                    os.chmod(highs_file, 0o755)
        elif sys.platform.startswith("win32"):
            glpsol_file = str(self.bin_dir / "glpsol.exe")
            highs_file = str(self.bin_dir / "highs.exe")
        flextool_model_file = str(self.flextool_dir / "flextool.mod")
        flextool_base_data_file = str(self.flextool_dir / "flextool_base.dat")
        glp_solution_file = str(self.root_dir / "glpsol_solution.txt")
        mps_file = str(self.root_dir / "flextool.mps")
        highs_option_file = str(self.bin_dir / "highs.opt")
        cplex_sol_file = str(self.root_dir / "cplex.sol")
        flextool_sol_file = str(self.root_dir / "flextool.sol")
        if solver == "glpsol":
            only_glpsol = [glpsol_file, '--model', flextool_model_file, '-d', flextool_base_data_file, '--cbg','-w', glp_solution_file] + sys.argv[3:]
            try:
                completed = subprocess.run(only_glpsol)
            except Exception as e:
                self.logger.exception(f"Error occurred: {e}")
                sys.exit(1)
            if completed.returncoode != 0:
                self.logger.error(f'glpsol failed: {completed.returncode}')
                sys.exit(completed.returncode)
            
            #checking if solution is infeasible. This is quite clumsy way of doing this, but the solvers do not give infeasible exitstatus
            with open('glpsol_solution.txt','r') as inf_file:
                inf_content = inf_file.read() 
                if 'INFEASIBLE' in inf_content:
                    self.logger.error(f"The model is infeasible. Check the constraints.")
                    sys.exit(1)

        elif solver == "highs" or solver == "cplex":
            highs_step1 = [glpsol_file, '--check', '--model', flextool_model_file, '-d', flextool_base_data_file,
                           '--wfreemps', mps_file] + sys.argv[3:]
            completed = subprocess.run(highs_step1)
            if completed.returncode != 0:
                self.logger.error(f'glpsol mps writing failed: {completed.returncode}')
                sys.exit(completed.returncode)
            print("GLPSOL wrote the problem as MPS file\n")

            #check if the problem has columns(nodes)
            with open(mps_file, 'r') as mps_file_handle:
                mps_content = mps_file_handle.read() 
                if 'Columns:    0' in mps_content:
                    self.logger.error(f"The problem has no columns. Check that the model has nodes with entity alternative: true")
                    sys.exit(-1)

            if solver == "highs":
                highs_step2 = [highs_file, mps_file, f"--options_file={highs_option_file}"] + \
                              [''.join(['--presolve='] + [self.highs_presolve.get(current_solve, "on")])] + \
                              [''.join(['--solver='] + [self.highs_method.get(current_solve, "choose")])] + \
                              [''.join(['--parallel='] + [self.highs_parallel.get(current_solve, "off")])]
                completed = subprocess.run(highs_step2)
                if completed.returncode != 0:
                    self.logger.error(f'Highs solver failed: {completed.returncode}')
                    sys.exit(completed.returncode)
                print("HiGHS solved the problem\n")
                
                #checking if solution is infeasible. This is quite clumsy way of doing this, but the solvers do not give infeasible exitstatus
                with open('HiGHS.log','r') as inf_file:
                    inf_content = inf_file.read() 
                    if 'Model   status      : Infeasible' in inf_content:
                        self.logger.error(f"The model is infeasible. Check the constraints.")
                        sys.exit(1)
            
            elif solver == "cplex": #or gurobi
                if current_solve not in self.solver_precommand.keys():
                    if solver == "cplex":
                        if current_solve not in self.solver_arguments.keys():
                            cplex_step = ['cplex', '-c', 'read', mps_file, 'opt', 'write', cplex_sol_file, 'quit']  + sys.argv[3:]
                        else:
                            cplex_step = ['cplex', '-c', 'read', mps_file]
                            cplex_step += self.solver_arguments[current_solve]
                            cplex_step += ['opt', 'write', cplex_sol_file, 'quit']
                            cplex_step += sys.argv[3:]

                        completed = subprocess.run(cplex_step)
                        if completed.returncode != 0:
                            self.logger.error(f'Cplex solver failed: {completed.returncode}')
                            sys.exit(completed.returncode) 
                        
                        completed = self.cplex_to_glpsol(cplex_sol_file, flextool_sol_file)
                else:
                    s_wrapper = self.solver_precommand[current_solve]
                    if solver == "cplex":
                        if current_solve not in self.solver_arguments.keys():
                            cplex_step = [s_wrapper, 'cplex', '-c', 'read', mps_file,'opt', 'write', cplex_sol_file, 'quit']  + sys.argv[3:]
                        else:
                            cplex_step = [s_wrapper, 'cplex', '-c', 'read', mps_file]
                            cplex_step += self.solver_arguments[current_solve]
                            cplex_step += ['opt', 'write', cplex_sol_file, 'quit']
                            cplex_step += sys.argv[3:]

                        completed = subprocess.run(cplex_step)
                        if completed.returncode != 0:
                            self.logger.error(f'Cplex solver failed: {completed.returncode}')
                            sys.exit(completed.returncode) 
                        
                        completed = self.cplex_to_glpsol(cplex_sol_file, flextool_sol_file)


            highs_step3 = [glpsol_file, '--model', flextool_model_file, '-d', flextool_base_data_file, '-r',
                        flextool_sol_file] + sys.argv[3:]
            completed = subprocess.run(highs_step3)
            if completed.returncode == 0:
                print("GLPSOL wrote the results into csv files\n")
        else:
            self.logger.error(f"Unknown solver '{solver}'. Currently supported options: highs, glpsol, cplex.")
            sys.exit(-1)
        return completed.returncode

    def cplex_to_glpsol(self,cplexfile,solutionfile): 
        
        try:
            tree = ET.parse(cplexfile)
        except (OSError):
            self.logger.error('The CPLEX solver does not produce a solution file if the problem is infeasible. Check the constraints, more info at cplex.log')
            sys.exit(-1)
        root = tree.getroot()

        if root.find('header').get('solutionStatusString') == "optimal":
            with open(solutionfile,'w') as glpsol_file:
                
                obj = root.find('header').get('objectiveValue')

                for constraint in root.iter('constraint'):
                    rows = constraint.get('index')
                rows = int(rows) + 2

                for variable in root.iter('variable'):
                    col = variable.get('index')
                col = int(col) + 1
                
                glpsol_file.write("s bas "+str(rows)+" "+str(col)+" f f "+obj+"\n")
                
                #For some reason the glpsol constraint the first variable row to be the objective function value.
                #This is not stated anywhere in the glpk documentation
                glpsol_file.write("i 1 b "+obj+" 0\n")
            
                for constraint in root.iter("constraint"):
                    slack = constraint.get('slack')
                    index = int(constraint.get('index')) + 2
                    status = constraint.get('status')
                    dual = constraint.get('dual')
                    
                    if status == "BS":
                        status = 'b'
                    elif status == "LL":
                        status = 'l'
                    elif status == "UL":
                        status = 'u'
                    
                    glpsol_file.write("i"+" "+str(index)+" "+status+" "+slack+" "+dual+"\n")

                for variable in root.iter('variable'):
                    val = variable.get('value')
                    index = int(variable.get('index')) +1
                    status = variable.get('status')
                    reduced = variable.get('reducedCost')
                    
                    if status == "BS":
                        status = 'b'
                    elif status == "LL":
                        status = 'l'
                    elif status == "UL":
                        status = 'u'

                    glpsol_file.write("j"+" "+str(index)+" "+status+" "+val+" "+reduced+"\n")
                
                glpsol_file.write("e o f")
        elif root.find('header').get('solutionStatusString') == "integer optimal solution":
            with open(solutionfile,'w') as glpsol_file:
                
                obj = root.find('header').get('objectiveValue')

                for constraint in root.iter('constraint'):
                    rows = constraint.get('index')
                rows = int(rows) + 2

                for variable in root.iter('variable'):
                    col = variable.get('index')
                col = int(col) + 1
                
                glpsol_file.write("s mip "+str(rows)+" "+str(col)+" o "+obj+"\n")
                
                #For some reason the glpsol requires the first constraint row to be the objective function value.
                #This is not stated anywhere in the glpk documentation
                glpsol_file.write("i 1 "+obj+"\n")
            
                for constraint in root.iter("constraint"):
                    slack = constraint.get('slack')
                    index = int(constraint.get('index')) + 2
                    
                    glpsol_file.write("i"+" "+str(index)+" "+slack+"\n")

                for variable in root.iter('variable'):
                    val = variable.get('value')
                    index = int(variable.get('index')) +1

                    glpsol_file.write("j"+" "+str(index)+" "+val+"\n")
                
                glpsol_file.write("e o f")
        else:
            self.logger.error(f"Optimality could not be reached. Check the flextool.sol file for more")
            sys.exit(1)
        
        return 0


    def get_active_time(self, current_solve, timeblocks_used_by_solves, timeblocks, timelines, timeblocks__timelines):
        """
        Maps periods to their corresponding timeline entries for a given solve.

        Returns a dict mapping period IDs to lists of (timestep, index, value) tuples.
        """
        active_time = defaultdict(list)

        # Skip if not current solve
        if current_solve not in timeblocks_used_by_solves:
            raise ValueError(f"{current_solve}: Current solve does not have period_timeblockSet defined.")

        for period, timeblock_id in timeblocks_used_by_solves[current_solve]:
            # Get timeline ID for this timeblock
            timeline_id = timeblocks__timelines.get(timeblock_id, [None])[0]
            if not timeline_id:
                continue

            # Get timeline data
            timeline_data = timelines.get(timeline_id, [])
            if not timeline_data:
                continue

            # Process each timeblock definition
            for start_time, duration in timeblocks[timeblock_id]:
                # Find starting index in timeline
                for idx, (time, value) in enumerate(timeline_data):
                    if time == start_time:
                        # Add entries for duration
                        for step in range(int(float(duration))):
                            if idx + step < len(timeline_data):
                                entry = timeline_data[idx + step]
                                active_time[period].append((entry[0], idx + step, entry[1]))
                        break

        if not active_time:
            raise ValueError(f"{current_solve}: Failed to map to timeline. Check period_timeblockSet, "
                             "realized_periods, timeblockSet and timeline definitions.")

        return active_time

    def make_step_jump(self, active_time_list, period__branch, solve_branch__time_branch_list):
        """
        make a file that indicates the length of jump from one simulation step to next one.
        the final line should always contain a jump to the first line.

        length of jump is the number of lines needed to advance in the timeline specified in step_duration.csv

        :param steplist: active steps used in the solve
        :param duration: duration of every timestep
        :return:
        """
        step_lengths = []
        period_start_pos = 0
        period_counter = -1
        first_period_name = list(active_time_list)[0]
        last_period_name = list(active_time_list)[-1]
        for period, active_time in reversed(active_time_list.items()):
            period_counter -= 1
            period_last = len(active_time)
            block_last = len(active_time) - 1
            if period == first_period_name:
                previous_period_name = last_period_name
            else:
                previous_period_name = list(active_time_list)[period_counter]
            for i, step in enumerate(reversed(active_time)):
                j = period_last - i - 1
                if j > 0:  # handle the first element of the period separately below
                    jump = active_time[j][1] - active_time[j - 1][1]
                    if jump > 1:
                        step_lengths.insert(period_start_pos, (period, step[0], active_time[j - 1][0], active_time[block_last][0], period, active_time[j - 1][0], jump))
                        block_last = j - 1
                    else:
                        step_lengths.insert(period_start_pos, (period, step[0], active_time[j - 1][0], active_time[j - 1][0], period, active_time[j - 1][0], jump))
                else:  # first time step of the period is handled here
                    #three options (period,period) is the realized, (period, branch) are the branches in the realized period, 
                    #(other_period,branch): continuing branch to the next period
                    if (period, period) not in period__branch:
                        for i in period__branch:
                            if i[1] == period:
                                original_period = i[0]
                        if (original_period,original_period) in period__branch and original_period in active_time_list.keys():
                            jump = active_time[j][1] - active_time[-1][1]
                            step_lengths.insert(period_start_pos, (period, step[0], active_time[j - 1][0], active_time[block_last][0], period, active_time_list[period][-1][0], jump))
                        elif (original_period,original_period) in period__branch: 
                            #if branching happens in the first timestep of a period
                            #find the last realized period
                            past = False
                            #previous_realized_period = None
                            #for solve_period, a_t in reversed(active_time_list.items()):
                            #    if past:
                            #        if (solve_period, solve_period) in period__branch:
                            #            previous_realized_period = solve_period
                            #            break
                            #    else:
                            #        if solve_period == period:
                            #            past = True
                            jump = active_time[j][1] - active_time[-1][1]
                            step_lengths.insert(period_start_pos, (period, step[0], active_time[j - 1][0], active_time[block_last][0], period, active_time_list[period][-1][0], jump))   
                        else:
                            #if branch continuing in the next period
                            #find the previous branch with the same time_branch
                            for sb_tb in solve_branch__time_branch_list:
                                if sb_tb[0] == period:
                                    time_branch = sb_tb[1]
                            past = False
                            found = False
                            previous_period_with_branch = None
                            for solve_period, a_t in reversed(active_time_list.items()):
                                if past:
                                    for sb_tb in solve_branch__time_branch_list:
                                        if sb_tb[0] == solve_period and sb_tb[1] == time_branch:
                                            previous_period_with_branch = solve_period
                                            found = True
                                    if found:
                                        break
                                else:
                                    if solve_period == period:
                                        past = True

                            jump = active_time[j][1] - active_time_list[previous_period_with_branch][-1][1]
                            step_lengths.insert(period_start_pos, (period, step[0], active_time[j - 1][0], active_time[block_last][0], previous_period_with_branch, active_time_list[previous_period_with_branch][-1][0], jump))
                        
                    else:
                        jump = active_time[j][1] - active_time_list[previous_period_name][-1][1]
                        step_lengths.insert(period_start_pos, (period, step[0], active_time[j - 1][0], active_time[block_last][0], previous_period_name, active_time_list[previous_period_name][-1][0], jump))
        return step_lengths

    def write_step_jump(self, step_lengths):
        """
        write step_jump.csv according to spec.

        :param step_lengths:
        :return:
        """

        headers = ("period", "time", "previous", "previous_within_block", "previous_period", "previous_within_solve", "jump")
        with open("solve_data/step_previous.csv", 'w', newline='\n') as stepfile:
            writer = csv.writer(stepfile, delimiter=',')
            writer.writerow(headers)
            writer.writerows(step_lengths)

    @staticmethod
    def get_first_steps(steplists):
        """
        get the first step of the current solve and the next solve in execution order.
        :param steplists: Dictionary containg steplist for each solve, in order
        :return: Return a dictionary containing tuples of current_first, next first
        """
        solve_names = list(steplists.keys())
        starts = OrderedDict()
        for index, name in enumerate(solve_names):
            # last key is a different case
            if index == (len(solve_names) - 1):
                starts[name] = (steplists[name][0],)
            else:
                starts[name] = (steplists[solve_names[index]][0], steplists[solve_names[index + 1]][0])
        return starts

    @staticmethod
    def write_first_steps(timeline, filename):
        """
        write to file the first step of each period
        
        :param steps: a tuple containing the period and the timestep
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period,step\n')
            for period_name, period in timeline.items():
                for item in period[:1]:
                    outfile.write(period_name + ',' + item[0] + '\n')

    def write_last_steps(self, timeline, filename):
        """
        write to file the last step of each period

        :param steps: a tuple containing the period and the timestep
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period,step\n')
            for period_name, period in timeline.items():
                for item in period[-1:]:
                    outfile.write(period_name + ',' + item[0] + '\n')
    
    def write_last_realized_step(self, realized_timeline, solve, filename):
        """
        write to file the last step of timeline

        :param steps: a tuple containing the period and the timestep
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period,step\n')
            out = []
            has_realized_period = False
            for period_name, period in realized_timeline.items():
                if (solve, period_name) in self.realized_periods:
                    last_realized_period = (period_name,period)
                    has_realized_period = True
            if has_realized_period: 
                for item in last_realized_period[1][-1:]:
                    out = [period_name, item[0]]
                    outfile.write(out[0] + ',' + out[1] + '\n')

    @staticmethod
    def write_periods(solve, periods, filename):
        """
        write to file a list of periods based on the current solve and
        a list of tuples with the solve as the first element in the tuple
        :param solve: current solve
        :param filename: filename to write to
        :param periods: list of tuples with solve and periods to be printed to the file
        :return: nothing
        """
        with open(filename, 'w') as outfile:
            # prepend with a header
            outfile.write('period\n')
            for item in periods:
                if item[0] == solve:
                    outfile.write(item[1] + '\n')

    @staticmethod
    def write_solve_status(first_state, last_state, nested = False):
        """
        make a file solve_first.csv that contains information if the current solve is the first to be run

        :param first_state: boolean if the current solve is the first
        :param last_state: boolean if the current solve is the last

        """
        if not nested:
            with open("input/p_model.csv", 'w') as p_model_file:
                p_model_file.write("modelParam,p_model\n")
                if first_state:
                    p_model_file.write("solveFirst,1\n")
                else:
                    p_model_file.write("solveFirst,0\n")
                if last_state:
                    p_model_file.write("solveLast,1\n")
                else:
                    p_model_file.write("solveLast,0\n")
        else:
            with open("solve_data/p_nested_model.csv", 'w') as p_model_file:
                p_model_file.write("modelParam,p_nested_model\n")
                if first_state:
                    p_model_file.write("solveFirst,1\n")
                else:
                    p_model_file.write("solveFirst,0\n")
                if last_state:
                    p_model_file.write("solveLast,1\n")
                else:
                    p_model_file.write("solveLast,0\n")

    @staticmethod
    def write_currentSolve(solve, filename):
        """
        make a file with the current solve name
        """
        with open(filename, 'w') as solvefile:
            solvefile.write("solve\n")
            solvefile.write(solve + "\n")

    @staticmethod
    def write_empty_investment_file():
        """
        make a file p_entity_invested.csv that will contain capacities of invested and divested processes. For the first solve it will be empty.
        """
        with open("solve_data/p_entity_invested.csv", 'w') as firstfile:
            firstfile.write("entity,p_entity_invested\n")
        with open("solve_data/p_entity_divested.csv", 'w') as firstfile:
            firstfile.write("entity,p_entity_divested\n")
        with open("solve_data/p_entity_period_existing_capacity.csv", 'w') as firstfile:
            firstfile.write("entity,period,p_entity_period_existing_capacity,p_entity_period_invested_capacity\n")

    @staticmethod
    def write_empty_storage_fix_file():
        with open("solve_data/fix_storage_price.csv", 'w') as firstfile:
            firstfile.write("node, period, step, ndt_fix_storage_price\n")
        with open("solve_data/fix_storage_quantity.csv", 'w') as firstfile:
            firstfile.write("node, period, step, ndt_fix_storage_quantity\n")
        with open("solve_data/fix_storage_usage.csv", 'w') as firstfile:
            firstfile.write("node, period, step, ndt_fix_storage_usage\n")
        with open("solve_data/p_roll_continue_state.csv", 'w') as firstfile:
            firstfile.write("node, p_roll_continue_state\n")

    @staticmethod
    def write_headers_for_empty_output_files(filename, header):
        """
        make an empty output file with headers
        """
        with open(filename, 'w') as firstfile:
            firstfile.write(header+"\n")

    def write_realized_dispatch(self, realized_time_list, solve):
        """
        write the timesteps to be realized for the dispatch decisions
        """
        with open("solve_data/realized_dispatch.csv", 'w') as realfile:
            realfile.write("period,step\n")
            for period, realized_time in realized_time_list.items():
                if (solve,period) in self.realized_periods:
                    for i in realized_time:
                        realfile.write(period+","+i[0]+"\n")

    def write_fix_storage_timesteps(self,active_time_list,solve):
        """
        write the timesteps to where the storage is fixed for included solves
        """
        with open("solve_data/fix_storage_timesteps.csv", 'w') as realfile:
            realfile.write("period,step\n")
            for period, active_time in active_time_list.items():
                if (solve,period) in self.fix_storage_periods:
                    for i in active_time:
                        realfile.write(period+","+i[0]+"\n")
    
    @staticmethod
    def write_branch__period_relationship(period__branch, filename):
        """
        write the period_branch relatioship
        """
        with open(filename, 'w') as realfile:
            realfile.write("period,branch\n")
            for row in period__branch:
                realfile.write(row[0]+","+row[1]+"\n")

    def write_all_branches(self,period__branch_list, solve_branch__time_branch_list):
        """
        write all branches in all solves
        """
        branches = []
        for solve in period__branch_list:
                for row in period__branch_list[solve]:
                    if row[1] not in branches:
                        branches.append(row[1])
        with open("solve_data/branch_all.csv", 'w') as realfile:
            realfile.write("branch\n")
            for branch in branches:
                realfile.write(branch+"\n")

        timeseries_names=[
        'pbt_node_inflow.csv',
        'pbt_node.csv',
        'pbt_process.csv',
        'pbt_profile.csv',
        'pbt_process_source.csv',
        'pbt_process_sink.csv',
        'pbt_reserve__upDown__group.csv']

        time_branches = []
        for filename in timeseries_names:
            with open('input/'+filename, 'r') as blk:
                filereader = csv.reader(blk, delimiter=',')
                headers = next(filereader)
                while True:
                    try:
                        datain = next(filereader)
                        if datain[1] not in time_branches:
                            time_branches.append(datain[1])
                        if datain[1] == "":
                            self.logger.error("Empty branch name in timeseries: "+ filename + " , check that there is no empty row at the end of the array")
                            sys.exit(-1)
                    except StopIteration:
                        break

        for solve__branch in solve_branch__time_branch_list:
            if solve__branch[1] not in time_branches:
                time_branches.append(solve__branch[1])
        with open("solve_data/time_branch_all.csv", 'w') as realfile:
            realfile.write("time_branch\n")
            for time_branch in time_branches:
                realfile.write(time_branch+"\n")
         
    def write_solve_branch__time_branch_list_and_weight(self, complete_solve, active_time_list, solve_branch__time_branch_list, branch_start_time, period__branch_lists):
        """
        write the the weights and which one of the branches is the realized (used on the realized time and if not stochastic)
        """
        time_branch_weight = defaultdict()
        if branch_start_time != None:
            for row in self.stochastic_branches[complete_solve]:
                if branch_start_time[0] == row[0] and branch_start_time[1] == row[2]:
                    time_branch_weight[row[1]] = row[4]

        with open("solve_data/solve_branch_weight.csv", 'w') as realfile:
            realfile.write("branch,p_branch_weight_input\n")
            for solve_branch__time_branch in solve_branch__time_branch_list:
                #the realized part always has the weight of 1
                if (solve_branch__time_branch[0], solve_branch__time_branch[0]) in period__branch_lists:
                    realfile.write(solve_branch__time_branch[0] +","+ '1.0'+"\n")
                elif solve_branch__time_branch[1] in time_branch_weight.keys() and solve_branch__time_branch[0] in active_time_list.keys():
                    realfile.write(solve_branch__time_branch[0] +","+ str(time_branch_weight[solve_branch__time_branch[1]])+"\n")

        with open("solve_data/solve_branch__time_branch.csv", 'w') as realfile:
            realfile.write("period,branch\n")
            for solve_branch__time_branch in solve_branch__time_branch_list:
                realfile.write(solve_branch__time_branch[0]+","+solve_branch__time_branch[1]+"\n")

    def write_first_and_last_periods(self, active_time_list, period__timeblocks_in_this_solve, period__branch_list):
        """
        write first and last periods (timewise) for the solve
        Assumes that the periods in right order in active_time_list, but gets the multiple branches as last
        """
        period_first_of_solve = list(active_time_list.keys())[0]
        period_last = []
        period_last.append(list(active_time_list.keys())[-1])
        time_step_last = active_time_list[period_last[0]][-1][0]

        for period in active_time_list.keys():
            if active_time_list[period][-1][0] == time_step_last and period != period_last[0]:
                period_last.append(period)
        
        with open("solve_data/period_last.csv", 'w') as realfile:
            realfile.write("period\n")
            for period in period_last:
                realfile.write(period +"\n")
        
        period_first_of_solve_list = []
        for period__branch in period__branch_list:
            if period__branch[0] == period_first_of_solve:
                period_first_of_solve_list.append(period__branch[1])
        
        with open("solve_data/period_first_of_solve.csv", 'w') as realfile:
            realfile.write("period\n")
            for period in period_first_of_solve_list:
                realfile.write(period+"\n")

        period_first = period__timeblocks_in_this_solve[0][0]
        period_first_list = []
        for period__branch in period__branch_list:
            if period__branch[0] == period_first:
                period_first_list.append(period__branch[1])

        with open("solve_data/period_first.csv", 'w') as realfile:
            realfile.write("period\n")
            for period in period_first_list:
                realfile.write(period+"\n")

        
    #these exist to connect timesteps from two different timelines or aggregated versions of one
    def connect_two_timelines(self,period,first_solve,second_solve, period__branch):
        first_period_timeblocks = self.timeblocks_used_by_solves[first_solve]
        second_period_timeblocks = self.timeblocks_used_by_solves[second_solve]
        for row in period__branch:
            if row[1] == period:
                real_period = row[0]
        for period_timeblock in first_period_timeblocks:
            if period_timeblock[0] == real_period:
                first_timeblock = period_timeblock[1]
        for period_timeblock in second_period_timeblocks:
            if period_timeblock[0] == real_period:
                second_timeblock = period_timeblock[1]

        first_timeline = self.timeblocks__timeline[first_timeblock][0]
        second_timeline = self.timeblocks__timeline[second_timeblock][0]

        first_timeline_duration_from_start = OrderedDict()
        second_timeline_duration_from_start = OrderedDict()
        counter = 0
        for timestep in self.timelines[first_timeline]:
            first_timeline_duration_from_start[timestep[0]] = counter
            counter += float(timestep[1])
        counter = 0
        for timestep in self.timelines[second_timeline]:
            second_timeline_duration_from_start[timestep[0]] = counter
            counter += float(timestep[1])
    
        return first_timeline_duration_from_start,second_timeline_duration_from_start

    def find_previous_timestep(self, from_active_time_list, period_timestamp, this_solve, from_solve, period__branch):
        
        this_timeline_duration_from_start, from_timeline_duration_from_start = self.connect_two_timelines(period_timestamp[0],this_solve,from_solve, period__branch)

        for row in period__branch:
            if row[1] == period_timestamp[0]:
                real_period = row[0]
        from_start = this_timeline_duration_from_start[period_timestamp[1]]
        last_timestep = from_active_time_list[real_period][0][0]
        previous_timestep = from_active_time_list[real_period][-1][0] #last is the default, as the last timestep can be shorter and cause issues
        for timestep in from_active_time_list[real_period]:
            if from_timeline_duration_from_start[timestep[0]] > from_start:
                previous_timestep = last_timestep 
                break
            last_timestep = timestep[0]
        return previous_timestep

    def find_next_timestep(self, from_active_time_list, period_timestamp, this_solve, from_solve):

        this_timeline_duration_from_start, from_timeline_duration_from_start = self.connect_two_timelines(period_timestamp[0],this_solve,from_solve,[(period_timestamp[0],period_timestamp[0])])

        from_start = this_timeline_duration_from_start[period_timestamp[1]]
        next_timestep = from_active_time_list[period_timestamp[0]][-1][0] #last is the default, as the last timestep can be shorter and cause issues
        for timestep in from_active_time_list[period_timestamp[0]]:
            if from_timeline_duration_from_start[timestep[0]] >= from_start:
                next_timestep = timestep[0]
                break
        return next_timestep

    def write_timeline_matching_map(self, upper_active_time_list, lower_active_time_list, upper_solve, lower_solve, period__branch):
        matching_map = OrderedDict()
        for period, lower_active_time in lower_active_time_list.items():
            #period_last = (period, lower_active_time[-1][0])
            for timestep in lower_active_time:
                period_timestep = (period, timestep[0])
                previous_timestep = self.find_previous_timestep(upper_active_time_list, period_timestep, lower_solve, upper_solve, period__branch)
                matching_map[period_timestep] = previous_timestep

        with open("solve_data/timeline_matching_map.csv", 'w') as realfile:
            realfile.write("period,step,upper_step\n")
            for period_timestep, upper_timestep in list(matching_map.items()):
                realfile.write(period_timestep[0]+","+period_timestep[1]+","+ upper_timestep+"\n")

    def create_rolling_solves(self, solve, full_active_time_list, jump, horizon, start = None, duration = -1):
        """
        splits the solve to overlapping sequence of solves "rolls" 
        """
        active_time_lists= OrderedDict()    
        realized_time_lists = OrderedDict()
        solves=[]
        starts=[]
        jumps= []
        horizons= []
        duration_counter = 0
        horizon_counter = 0
        jump_counter = 0
        started = False
        ended = False

        # search for the start, end and horizon time indexes
        for period, active_time in list(full_active_time_list.items()):
            for i, step in enumerate(active_time):
                if not ended:
                    if started:
                        if duration_counter >= float(duration) and duration != -1:
                            jumps.append(last_index)
                            horizons.append(last_index)
                            ended = True
                            break
                        if jump_counter >= float(jump):
                            jumps.append(last_index)
                            starts.append([period,i])
                            jump_counter -= float(jump)
                        if horizon_counter >= float(horizon):
                            horizons.append(last_index)
                            horizon_counter -= float(jump)
                        horizon_counter += float(step[2])
                        jump_counter += float(step[2])
                        duration_counter += float(step[2])
                        last_index = [period,i]
                    else:
                        if start == None or (start == [period, step[0]]):
                            starts.append([period, i])
                            started = True
                            horizon_counter += float(step[2])
                            jump_counter += float(step[2])
                            duration_counter += float(step[2])
                            last_index=[period,i]
        if started == False:
            self.logger.error("Start point not found")
            sys.exit(-1)
        # if there is start of the roll but not end, the end is the last index of the active time
        diff = len(starts)-len(horizons)
        for i in range(0,diff):
            horizons.append(last_index)
        diff = len(starts)-len(jumps)
        for i in range(0,diff):
            jumps.append(last_index)
        # create the active and realized timesteps from the start and end time indexes
        for index, roll_start in enumerate(starts): 
            active = OrderedDict()
            realized = OrderedDict()
            solve_name= solve+"_roll_" + str(self.roll_counter[solve])
            self.roll_counter[solve]+=1
            solves.append(solve_name) 
            if roll_start[0]==horizons[index][0]: #if the whole roll is in the same period
                active[roll_start[0]] = full_active_time_list[roll_start[0]][roll_start[1]:horizons[index][1]+1]
            else:
                started = False
                for period, active_time in list(full_active_time_list.items()):
                    if started:
                        if period == horizons[index][0]:
                            active[period] = full_active_time_list[period][0:horizons[index][1]+1]
                            break
                        else:
                            active[period] = full_active_time_list[period]
                    elif period == roll_start[0]:
                        active[roll_start[0]] = full_active_time_list[period][roll_start[1]:]
                        started = True
            if roll_start[0]==jumps[index][0]:
                realized[roll_start[0]] = full_active_time_list[roll_start[0]][roll_start[1]:jumps[index][1]+1]
            else:
                started = False
                for period, active_time in list(full_active_time_list.items()):
                    if started:
                        if period == jumps[index][0]:
                            realized[period] = full_active_time_list[period][0:jumps[index][1]+1]
                            break
                        else:
                            realized[period] = full_active_time_list[period]
                    elif period == roll_start[0]:
                        realized[period] = full_active_time_list[period][roll_start[1]:]
                        started = True
            active_time_lists[solve_name] = active
            realized_time_lists[solve_name] = realized
        return solves, active_time_lists, realized_time_lists

    def define_solve(self, solve, parent_solve__roll = None, realized = [], start = None, duration = -1):
        complete_solves= OrderedDict() #complete_solve is for rolling, so that the rolls inherit the parameters of the whole solve
        active_time_lists= OrderedDict()    
        realized_time_lists = OrderedDict()
        full_active_time_list = OrderedDict()
        parent_roll_lists = OrderedDict()
        solves=[]

        #check that the lower level solves have periods only from of upper_level realizations
        full_active_time_list_own = self.get_active_time(solve, self.timeblocks_used_by_solves, self.timeblocks,self.timelines, self.timeblocks__timeline)
        if len(realized) != 0:
            # Make full_active_time_list to include only timesteps that are found in 'realized' periods.
            # After that, remove any periods from 'realised' are not in fix_storage, realized or realized_invest periods
            for key, item in list(full_active_time_list_own.items()):
                if key in realized :
                    full_active_time_list[key] = item
            periods_to_be_removed = []  # Cannot remove directly from the list that is being iterated
            for period in realized:
                if (solve,period) not in (self.fix_storage_periods + self.realized_periods + self.realized_invest_periods):
                    periods_to_be_removed.append(period)
            for period in periods_to_be_removed:
                realized.remove(period)
        else:
            # Create realized based on periods in realized_periods, realized_invest_periods and fix_storage_periods
            # and then use the timesteps that were fetched earlier with get_active_time directly
            ordered_periods = OrderedDict.fromkeys(
                self.realized_periods + self.realized_invest_periods + self.fix_storage_periods)
            for solve_period in ordered_periods:
                if solve_period[0] == solve:
                    realized.append(solve_period[1])
            full_active_time_list = full_active_time_list_own

        if solve in self.contains_solves.keys():
            contain_solves = self.contains_solves[solve]
        else:
            contain_solves = []
        if solve not in self.solve_modes.keys():
            self.solve_modes[solve] = "single_solve"

        if self.solve_modes[solve] == "rolling_window":
            #rolling_times: 0:jump, 1:horizon, 2:duration
            rolling_times = self.rolling_times[solve]
            if duration == -1:
                duration = float(rolling_times[2])
            period_start_timestep = start
            if start != None:
                start_timestep = self.find_next_timestep(full_active_time_list_own, start, parent_solve__roll[0], solve) # if the timestep is not in the lower timeline
                period_start_timestep = [start[0],start_timestep]
            
            roll_solves, roll_active_time_lists, roll_realized_time_lists = (
                self.create_rolling_solves(solve, full_active_time_list, float(rolling_times[0]), float(rolling_times[1]), period_start_timestep, duration))
            for i in roll_solves:
                complete_solves[i] = solve
                parent_roll_lists[i] = parent_solve__roll[1]

            active_time_lists.update(roll_active_time_lists)
            realized_time_lists.update(roll_realized_time_lists)
            
            # used for state start constraints so it should only be in the first solve of the whole nested level
            if parent_solve__roll[1] != None:
                if parent_solve__roll[1] in self.first_of_complete_solve:
                    self.first_of_complete_solve.append(roll_solves[0])
            else:
                self.first_of_complete_solve.append(roll_solves[0])
            self.last_of_solve.append(roll_solves[-1])

            if contain_solves:
                if len(contain_solves) > 1:
                    logging.error("More than one solve in a rolling solve, not managed")
                    sys.exit(-1)
                else:
                    contains_solve = contain_solves[0]
                for index, roll in enumerate(roll_solves):
                    solves.append(roll)
                    #creating the start time for the rolling. This is next timestep of the roll timeline from the first [period, timestamp] of the active time of the parent roll
                    if index != 0:
                        start = [list(roll_active_time_lists[roll].items())[0][0],list(roll_active_time_lists[roll].items())[0][1][0][0]]
                    else:
                        start = None
                    #upper_jump = lower_duration 
                    duration = float(rolling_times[0])
                    inner_solves, inner_complete_solve, inner_active_time_lists, inner_realized_time_lists, inner_parent_roll_lists = (
                        self.define_solve(contains_solve, [solve, roll], realized, start, duration))
                    solves += inner_solves
                    complete_solves.update(inner_complete_solve)
                    parent_roll_lists.update(inner_parent_roll_lists)
                    active_time_lists.update(inner_active_time_lists)
                    realized_time_lists.update(inner_realized_time_lists)
            else:
                solves += roll_solves
        else:
            solves.append(solve)
            parent_roll_lists[solve] = parent_solve__roll[1]
            complete_solves[solve]= solve #complete_solve is for rolling, so that the rolls inherit the parameters of the solve. If not rolling, the solve is its own complete solve
            active_time_lists[solve] = full_active_time_list
            realized_time_lists[solve]= full_active_time_list
            self.first_of_complete_solve.append(solve)
            self.last_of_solve.append(solve)

            for contain_solve in contain_solves:
                inner_solves, inner_complete_solve, inner_active_time_lists, inner_realized_time_lists, inner_parent_roll_lists = (
                    self.define_solve(contain_solve, [solve, solve], realized))
                solves += inner_solves
                complete_solves.update(inner_complete_solve)
                parent_roll_lists.update(inner_parent_roll_lists)
                active_time_lists.update(inner_active_time_lists)
                realized_time_lists.update(inner_realized_time_lists)

        return solves, complete_solves, active_time_lists, realized_time_lists, parent_roll_lists
    
    def create_stochastic_periods(self, stochastic_branches, solves, complete_solves, active_time_lists, realized_time_lists):
        
        period__branch_lists = defaultdict(list)
        solve_branch__time_branch_lists = defaultdict(list)
        jump_lists = OrderedDict()
        branch_start_time_lists = defaultdict() 
        for solve in solves:
            new_realized_time_list = OrderedDict()
            new_active_time_list = OrderedDict()
            info = stochastic_branches[complete_solves[solve]]
            active_time_list = active_time_lists[solve]
            realized_time_list = realized_time_lists[solve]
            branched = False
            next_analysis_found = False
            branches = []
            branch_start_time_lists[solve] = None
            for period, active_time in active_time_list.items():
                first_step = (period, active_time[0][0])
                break

            #check that the start times of the solves can be found from the stochastic_branches parameter
            found_start = False
            for row in info:
                if first_step[1] == row[2] and "yes" == row[3]:
                    found_start = True
            if found_start == False and len(info) != 0:
                self.logger.error("A realized start time of the solve cannot be found from the stochastic_branches parameter. "+
                              "Check that stochastic_branches has a realized : yes, branch for the start of the solve" +
                               "and that the possible rolling_jump matches with the branch starts")
                sys.exit(-1)
            for period, active_time in active_time_list.items():
                realized_end = None
                if not branched:
                    period__branch_lists[solve].append((period, period))
                    #get all start times
                    start_times = defaultdict(list)
                    for row in info:
                        if row[0]==period:
                            start_times[row[2]].append((row[1], row[4], row[3]))
                    for step in active_time:
                        if step[0] in start_times.keys():
                            branched = True
                            branch_start_time_lists[solve] = (period,step[0])
                            new_active_time_list[period] = active_time
                            new_realized_time_list[period] = realized_time_list[period]
                            for branch__weight__real in start_times[step[0]]:
                                branch = branch__weight__real[0]
                                branches.append(branch)
                                solve_branch = period + "_" + branch
                                # if the weight is zero, do not add to the timeline
                                if float(branch__weight__real[1]) != 0.0 and branch != period and branch__weight__real[2] != "yes":
                                    new_active_time_list[solve_branch] = active_time[0:]
                                    solve_branch__time_branch_lists[solve].append((solve_branch, branch))
                                period__branch_lists[solve].append((period, solve_branch))
                                #get timesteps
                                for i in active_time[0:]:
                                    self.stochastic_timesteps[solve].append((solve_branch, i[0]))
                            break   
                else:
                    # if the jump is longer than the period
                    for branch in branches:
                        solve_branch = period + "_" + branch
                        #new_realized_time_list[solve_branch] = realized_time_list[period]
                        period__branch_lists[solve].append((period,solve_branch))
                        solve_branch__time_branch_lists[solve].append((solve_branch, branch))
                        for i in active_time_list[period]:
                             self.stochastic_timesteps[solve].append((solve_branch, i[0]))
                if not branched:
                    new_active_time_list[period] = active_time_list[period]
                    if period in realized_time_list.keys():
                        new_realized_time_list[period] = realized_time_list[period]
            
            #find the realized branch for this start time
            for period, active_time in active_time_list.items():
                found = 0
                #before branching
                for row in info:
                    if row[0]==period and row[2] == active_time[0][0] and row[3] == 'yes':
                        found +=1
                        solve_branch__time_branch_lists[solve].append((period, row[1]))
                #after branching
                if found == 0 and branch_start_time_lists[solve] != None:
                    for row in info:
                        if row[0]==branch_start_time_lists[solve][0] and row[2] == branch_start_time_lists[solve][1] and row[3] == 'yes':
                            found +=1
                            solve_branch__time_branch_lists[solve].append((period, row[1]))
                if (branch_start_time_lists[solve] != None and found == 0) or found > 1:
                    self.logger.error("Each period should have one and only one realized branch. Found: " + str(found) + "\n")
                    sys.exit(-1)
            realized_time_lists[solve] = new_realized_time_list
            active_time_lists[solve] = new_active_time_list
            jump_lists[solve] = self.make_step_jump(new_active_time_list, period__branch_lists[solve], solve_branch__time_branch_lists[solve])

        return period__branch_lists, solve_branch__time_branch_lists, active_time_lists, jump_lists, realized_time_lists, branch_start_time_lists 
   
    def periodic_postprocess(self,groupby_map, method = None, arithmetic = "sum"):
        for key, group in list(groupby_map.items()):
            if method == "timewise":
                filepath = 'output/' + key + '__t.csv'
            else:
                filepath = 'output/' + key + '.csv'
            if os.path.exists(filepath):
                #get the relationship indicators from the start of the file
                if group[1]>1:
                    relationship_start_df=pd.read_csv(filepath, header = 0, nrows=group[1]-1)
                    if method == "timewise":
                        relationship_start_df.drop(["time"],axis = 1, inplace=True)
                    timestep_df = pd.read_csv(filepath,header = 0,skiprows=range(1,group[1]))
                else:
                    timestep_df = pd.read_csv(filepath,header = 0)
                if method == "timewise":
                    timestep_df.drop(["time"],axis = 1, inplace=True)
                
                #create a df with only group,solve,period cols, where the solve is the first of the group,period combo
                solve_period = timestep_df.filter(items= group[0] +["solve","period"])
                solve_first = solve_period.groupby(group[0] +["period"]).first().reset_index()
                cols = list(solve_first.columns)
                a,b = cols.index('period'),cols.index('solve')
                cols[a], cols[b] = cols[b], cols[a]
                solve_first= solve_first[cols]
                
                #group_by with group and period, sum numeric columns, other columns are removed
                if arithmetic == "sum":
                    if not timestep_df.empty:
                        modified= timestep_df.groupby(group[0]+["period"],group_keys=False).sum(numeric_only=True).reset_index()
                    else:
                        modified = timestep_df
                else:
                    if not timestep_df.empty:
                        modified = timestep_df.groupby(group[0]+["period"],group_keys=False).mean(numeric_only=True).reset_index()
                    else:
                        modified = timestep_df
                #combine with the solve name df
                combined = pd.merge(solve_first,modified)
                for col in combined.select_dtypes(include=['float']).columns:
                    combined[col] = combined[col].apply(lambda x: round(x,6))
                #put the relationship indicators back to the start of the file
                if group[1]>1:
                    combined = pd.concat([relationship_start_df,combined])

                if arithmetic == "sum":
                    combined.to_csv('output/' + key + '.csv',index=False, float_format= "%.6g")
                else:
                    combined.to_csv('output/' + key + '_average.csv',index=False, float_format= "%.6g")

    def combine_result_tables(self, inputfile1, inputfile2, outputfile, combine_headers = None, move_column = []):
        input1 = pd.read_csv(inputfile1,header = 0)
        input2 = pd.read_csv(inputfile2,header = 0)
        combined = pd.concat([input1,input2])
        #move columns to desired locations
        for column in move_column:
            name = combined.columns[column[0]]
            col = combined.pop(name)
            combined.insert(column[1],name,col)
        combined.to_csv(outputfile, index= False, float_format= "%.6g")
    
    def divide_column(self,inputfile,div_col_ind,to_cols_ind, remove = True):
        df = pd.read_csv(inputfile,header = 0)
        to_cols = list(df.columns[to_cols_ind])
        div_col = df.columns[div_col_ind]
        for i in to_cols:
            df[i]= df[i]/df[div_col]
        if remove:
            df = df.drop(div_col, axis = 1)
        df.to_csv(inputfile, index= False,float_format= "%.6g")
    
    def divide_group_with_another(self,inputfile, row_start_ind, from_col_ind, remove_cols_ind, remove = True):
        #assumption is that the all the rows of the first group are before any of the second
        #the postprocess groupping does this
        
        if row_start_ind != 1:
            #the relationship information is removed so that the datatype would be float not str
            relationship_start_df=pd.read_csv(inputfile, header = 0, nrows=row_start_ind-1)
            df = pd.read_csv(inputfile,header = 0, skiprows=range(1,row_start_ind))
        else:    
            df = pd.read_csv(inputfile,header = 0)
        from_col = df.columns[from_col_ind]
        
        rows = list(df.index)
        group_len = int(len(rows)/2) #should always be divisable by 2
        for row in rows: 
            if row<group_len:
                df.loc[row,from_col:] = df.loc[row,from_col:].div(df.iloc[row+group_len][from_col:])
        #remove divider rows
        remove_rows=[]
        for row in rows:
            if row>=group_len:
                remove_rows.append(row)
        if remove:
            df = df.drop(remove_rows, axis = 0)
        #remove indicator column
        remove_cols = list(df.columns[remove_cols_ind])
        for i in remove_cols:
            df = df.drop(i, axis = 1)

        for col in df.select_dtypes(include=['float']).columns:
            df[col] = df[col].apply(lambda x: round(x,6))

        #put the relationship back to the top
        if row_start_ind != 1:
            df = pd.concat([relationship_start_df,df])
        df.to_csv(inputfile, index= False,float_format= "%.6g")


    def run_model(self):
        """
        first read the solve configuration from the input files, then for each solve write the files that are needed
        By that solve into disk. separate the reading into a separate step since the input files need knowledge of multiple solves.
        """
        active_time_lists = OrderedDict()
        jump_lists = OrderedDict()
        solve_period_history = defaultdict(list)
        realized_time_lists = OrderedDict()
        complete_solve= OrderedDict()
        parent_roll = OrderedDict()
        period__branch_lists = OrderedDict()
        branch_start_time_lists = defaultdict()
        all_solves=[]

        try:
            os.mkdir('solve_data')
        except FileExistsError:
            print("solve_data folder existed")

        if not self.model_solve:
            self.logger.error("No model. Make sure the 'model' class defines solves [Array].")
            sys.exit(-1)
        solves = next(iter(self.model_solve.values()))
        if not solves:
            self.logger.error("No solves in model.")
            sys.exit(-1)
        
        for solve in solves:
            solve_solves, solve_complete_solve, solve_active_time_lists, solve_realized_time_lists, solve_parent_roll = self.define_solve(solve, [None,None], [])
            all_solves += solve_solves
            complete_solve.update(solve_complete_solve)
            parent_roll.update(solve_parent_roll)
            active_time_lists.update(solve_active_time_lists)
            realized_time_lists.update(solve_realized_time_lists)

        period__branch_lists, solve_branch__time_branch_lists, active_time_lists, jump_lists, realized_time_lists, branch_start_time_lists = self.create_stochastic_periods(self.stochastic_branches, all_solves, complete_solve, active_time_lists, realized_time_lists)

        real_solves = [] 
        for solve in solves: #real solves are the defined solves not including the individual rolls
            real_solves.append(solve)     
        for solve, inner_solves in list(self.contains_solves.items()):
            for inner_solve in inner_solves:
                real_solves.append(inner_solve)

        for solve in real_solves:
            #check that period__years_represented has only periods included in the solve
            new_years_represented = []
            for period__year in self.solve_period_years_represented[solve]:
                if any(period__year[0] == period__timeblockSet[0] for period__timeblockSet in self.timeblocks_used_by_solves[solve]):
                    new_years_represented.append(period__year)
            self.solve_period_years_represented[solve] = new_years_represented
            # get period_history from earlier solves
            for solve_2 in real_solves:
                if solve_2 == solve:
                    break
                for solve__period in (self.realized_periods+self.invest_periods+self.fix_storage_periods+self.realized_invest_periods):
                    if solve__period[0] == solve_2:
                        this_solve = self.solve_period_years_represented[solve_2]
                        for period in this_solve:
                            if period[0] == solve__period[1] and not any(period[0]== sublist[0] for sublist in solve_period_history[solve]):
                                    solve_period_history[solve].append((period[0], period[1]))
            # get period_history from this solve
            for period__year in self.solve_period_years_represented[solve]:
                if not any(period__year[0]== sublist[0] for sublist in solve_period_history[solve]):
                    solve_period_history[solve].append((period__year[0], period__year[1]))
            #if not defined, all the periods have the value 1
            if not self.solve_period_years_represented[solve]:
                for period__timeblockSet in self.timeblocks_used_by_solves[solve]:
                    if not any(period__timeblockSet[0]== sublist[0] for sublist in solve_period_history[solve]):
                        solve_period_history[solve].append((period__timeblockSet[0], 1))
        for solve in active_time_lists.keys():
            for period in active_time_lists[solve]:
                if (period,period) in period__branch_lists[solve] and not any(period== sublist[0] for sublist in solve_period_history[complete_solve[solve]]):
                    self.logger.error("The years_represented is defined, but not to all of the periods in the solve")
                    sys.exit(-1)

        first = True
        previous_complete_solve = None
        for i, solve in enumerate(all_solves):
            self.logger.info("Creating timelines for solve " + solve + " (" + str(i) + ")")
            complete_active_time_lists = self.get_active_time(complete_solve[solve], self.timeblocks_used_by_solves, self.timeblocks, self.timelines, self.timeblocks__timeline)
            self.write_full_timelines(self.stochastic_timesteps[solve], self.timeblocks_used_by_solves[complete_solve[solve]], self.timeblocks__timeline, self.timelines, 'solve_data/steps_in_timeline.csv')
            self.write_active_timelines(active_time_lists[solve], 'solve_data/steps_in_use.csv')
            self.write_active_timelines(complete_active_time_lists, 'solve_data/steps_complete_solve.csv', complete = True)
            self.write_step_jump(jump_lists[solve])
            self.logger.info("Creating period data")
            self.write_period_years(period__branch_lists[solve], solve_period_history[complete_solve[solve]], 'solve_data/period_with_history.csv')
            self.write_periods(complete_solve[solve], self.realized_invest_periods, 'solve_data/realized_invest_periods_of_current_solve.csv')
            #assume that if realized_invest_periods is not defined,but the invest_periods and realized_periods are defined, use realized_periods also as the realized_invest_periods
            if (not any(complete_solve[solve] == step[0] for step in self.realized_invest_periods)) and any(complete_solve[solve] == step[0] for step in self.invest_periods) and any(complete_solve[solve] == step[0] for step in self.realized_periods):
                 self.write_periods(complete_solve[solve], self.realized_periods, 'solve_data/realized_invest_periods_of_current_solve.csv')
            self.write_periods(complete_solve[solve], self.invest_periods, 'solve_data/invest_periods_of_current_solve.csv')
            self.write_years_represented(period__branch_lists[solve], self.solve_period_years_represented[complete_solve[solve]],'solve_data/p_years_represented.csv')
            self.write_period_years(period__branch_lists[solve], self.solve_period_years_represented[complete_solve[solve]],'solve_data/p_discount_years.csv')
            self.write_currentSolve(solve, 'solve_data/solve_current.csv')
            self.write_hole_multiplier(solve, 'solve_data/solve_hole_multiplier.csv')
            self.write_first_steps(active_time_lists[solve], 'solve_data/first_timesteps.csv')
            self.write_last_steps(active_time_lists[solve], 'solve_data/last_timesteps.csv')
            self.write_last_realized_step(realized_time_lists[solve], complete_solve[solve], 'solve_data/last_realized_timestep.csv')
            self.logger.info("Create realized timeline")
            self.write_realized_dispatch(realized_time_lists[solve],complete_solve[solve])
            self.write_fix_storage_timesteps(realized_time_lists[solve],complete_solve[solve])
            self.logger.info("Possible stochastics")
            self.write_branch__period_relationship(period__branch_lists[solve], 'solve_data/period__branch.csv')
            self.write_all_branches(period__branch_lists, solve_branch__time_branch_lists[solve])
            self.write_solve_branch__time_branch_list_and_weight(complete_solve[solve], active_time_lists[solve], solve_branch__time_branch_lists[solve], branch_start_time_lists[solve], period__branch_lists[solve])
            self.write_first_and_last_periods(active_time_lists[solve], self.timeblocks_used_by_solves[complete_solve[solve]], period__branch_lists[solve])

            #check if the upper level fixes storages
            if complete_solve[solve] in self.contains_solves.values() and any(complete_solve[parent_roll[solve]] == solve_period[0] for solve_period in self.fix_storage_periods): # check that the parent_roll exists and has storage fixing
                storage_fix_values_exist = True
            else:
                storage_fix_values_exist = False
            if storage_fix_values_exist:
                self.logger.info("Nested timeline matching")
                self.write_timeline_matching_map(active_time_lists[parent_roll[solve]], active_time_lists[solve], complete_solve[parent_roll[solve]], complete_solve[solve], period__branch_lists[solve])
            else:
                with open("solve_data/timeline_matching_map.csv", 'w') as realfile:
                    realfile.write("period,step,upper_step\n")
            #if timeline created from new step_duration, all timeseries have to be averaged or summed for the new timestep
            if previous_complete_solve != complete_solve[solve]:
                self.logger.info("Aggregating timeline and parameters for the new step size")
                self.create_averaged_timeseries(complete_solve[solve])
            previous_complete_solve = complete_solve[solve]
            if solve in self.first_of_complete_solve:
                first_of_nested_level = True
            else:
                first_of_nested_level = False
            if solve in self.last_of_solve:
                last_of_nested_level = True
            else:
                last_of_nested_level = False
            #if multiple storage solve levels, get the storage fix of the upper level, (not the fix of the previous roll):
            if storage_fix_values_exist:
                self.logger.info("Fetching storage parameters from the upper solve")
                shutil.copy("solve_data/fix_storage_quantity_"+ complete_solve[parent_roll[solve]]+".csv", "solve_data/fix_storage_quantity.csv")
                shutil.copy("solve_data/fix_storage_price_"+ complete_solve[parent_roll[solve]]+".csv", "solve_data/fix_storage_price.csv")
                shutil.copy("solve_data/fix_storage_usage_"+ complete_solve[parent_roll[solve]]+".csv", "solve_data/fix_storage_usage.csv")

            self.write_solve_status(first_of_nested_level,last_of_nested_level, nested = True)
            last = i == len(solves) - 1
            self.write_solve_status(first, last)
            if i == 0:
                first = False
                self.write_empty_investment_file()
                self.write_empty_storage_fix_file()
                self.write_headers_for_empty_output_files('output/costs_discounted.csv', 'param_costs,costs_discounted')
            self.logger.info("Starting model creation")
            exit_status = self.model_run(complete_solve[solve])
            if exit_status == 0:
                self.logger.info('Success!')
            else:
                self.logger.error(f'Error: {exit_status}')
                sys.exit(-1)
            #if multiple storage solve levels, save the storage fix of this level:
            if any(complete_solve[solve] == solve_period[0] for solve_period in self.fix_storage_periods):
                shutil.copy("solve_data/fix_storage_quantity.csv","solve_data/fix_storage_quantity_"+ complete_solve[solve]+".csv")
                shutil.copy("solve_data/fix_storage_price.csv", "solve_data/fix_storage_price_"+ complete_solve[solve]+".csv")
                shutil.copy("solve_data/fix_storage_usage.csv","solve_data/fix_storage_usage_"+ complete_solve[solve]+".csv")

        #produce periodic data as post-process for rolling window solves
        post_process_results = False
        for solve in complete_solve.keys():
            if self.solve_modes[complete_solve[solve]] == "rolling_window":
                post_process_results = True
        if post_process_results:
            #[[group by], relation dimensions]
            #sums the solves with same period
            period_only = {
            "group__process__node__period": [[],1],
            "node__period": [["node"],1],
            "unit__inputNode__period": [[],2],
            "unit__outputNode__period": [[],2],
            "connection_to_first_node__period": [[],3],
            "connection_to_second_node__period": [[],3],
            "connection__period": [[],3],
            "unit_cf__inputNode__period": [[],2],
            "unit_cf__outputNode__period": [[],2],
            "connection_cf__period":[[],3],
            "process__period_co2": [["class","process"],1],
            "unit_startup__period": [[],1],
            }
            #sums the timesteps of all solves in the period
            #used when some other calculation is needed
            timewise_groupby = {
            "annualized_dispatch_costs__period": [[],1],
            "group_node__period": [["group"],1],
            "unit_curtailment_share__outputNode__period": [["type"],2]
            }
            #average of all timesteps of all solves in the period
            timewise_average_groupby = {
            "process__reserve__upDown__node__period": [[],6],
            "unit_online__period": [[],1],
            }

            self.periodic_postprocess(period_only, method = "periodic", arithmetic= "sum")
            self.periodic_postprocess(timewise_groupby, method = "timewise", arithmetic= "sum")
            self.periodic_postprocess(timewise_average_groupby, method = "timewise", arithmetic= "average")
            self.combine_result_tables("output/annualized_investment_costs__period.csv","output/annualized_dispatch_costs__period.csv", "output/annualized_costs__period.csv")
            self.divide_column("output/group_node__period.csv",div_col_ind = 3, to_cols_ind=[5,6,7,8], remove = True)
            self.divide_group_with_another("output/unit_curtailment_share__outputNode__period.csv", row_start_ind= 2, from_col_ind = 3 ,remove_cols_ind = [0], remove = True)
            os.remove("output/annualized_dispatch_costs__period.csv")
        os.remove("output/annualized_dispatch_costs__period__t.csv")
        os.remove("output/annualized_investment_costs__period.csv")
        os.remove("output/group_node__period__t.csv")
        os.remove("output/unit_curtailment_share__outputNode__period__t.csv")
        if len(self.model_solve) > 1:
            self.logger.error(
                f'Trying to run more than one model - not supported. The results of the first model are retained.')
            sys.exit(-1)

    def entities_to_dict(self, db, cl, mode):
        entities = db.get_entity_items(entity_class_name=cl)
        if mode == "defaultdict":
            result = defaultdict(list)
        elif mode == "dict":
            result = dict()
        for entity in entities:
            if len(entity["entity_byname"]) > 1:
                result[entity["entity_byname"][0]] = list(entity["entity_byname"][1:])
            else:
                raise ValueError("Only one dimension in the entity, cannot make into a dict in entities_to_dict")
        return result


    def params_to_dict(self, db, cl, par, mode, str_to_list=False):
        print(par)
        all_params = db.get_parameter_value_items(entity_class_name=cl,
                                                 parameter_definition_name=par)
        if mode == "defaultdict":
            result = defaultdict(list)
        elif mode == "dict":
            result = dict()
        elif mode == "list":
            result = []
        for param in all_params:
            param_value = api.from_database(param["value"], param["type"])
            if mode == "defaultdict" or mode == "dict":
                if isinstance(param_value, api.Map):
                    if isinstance(param_value.values[0], float):
                        result[param["entity_name"]] = list(zip(list(param_value.indexes), list(map(float, param_value.values))))
                    elif isinstance(param_value.values[0], str):
                        result[param["entity_name"]] = list(zip(list(param_value.indexes), param_value.values))
                    elif isinstance(param_value.values[0], api.Map):
                        result[param["entity_name"]] = api.convert_map_to_table(param_value)
                    else:
                        raise TypeError("params_to_dict function does not handle other values than floats and strings")
                elif isinstance(param_value, api.Array):
                    result[param["entity_name"]] = param_value.values
                elif isinstance(param_value, float):
                    result[param["entity_name"]] = str(param_value)
                elif isinstance(param_value, str):
                    if str_to_list:
                        result[param["entity_name"]] = [param_value]
                    else:
                        result[param["entity_name"]] = param_value
            elif mode == "list":
                if isinstance(param_value, float):
                    result.append([param["entity_name"], param_value])
                elif isinstance(param_value, str):
                    result.append([param["entity_name"], param_value])
        return result

    def write_input(self, input_db_url, scenario_name=None):
        if scenario_name:
            scen_config = api.filters.scenario_filter.scenario_filter_config(scenario_name)
        with (DatabaseMapping(input_db_url) as db):
            if scenario_name:
                api.filters.scenario_filter.scenario_filter_from_dict(db, scen_config)
            if not os.path.exists("input"):
                os.makedirs("input", exist_ok=True)
            write_default_values(db, [("node", "penalty_up"), ("node", "penalty_down")],
                                 "class,paramName,default_value", "input/default_values.csv",
                                 filter_in_type=["float", "str", "bool"])
            write_parameter(db, [("commodity", "price")], "commodity,commodityParam,time,pt_commodity",
                            "input/pt_commodity.csv", filter_in_type=["1d_map"], filter_out_index="period", param_print=True)
            write_parameter(db, [("commodity", "price"), ("commodity", "co2_content")], "commodity,commodityParam,p_commodity",
                            "input/p_commodity.csv", filter_in_type=["float", "str"], param_print=True)
            write_parameter(db, [("commodity", "price")], "commodity,commodityParam,period,pd_commodity",
                            "input/pd_commodity.csv", filter_in_type=["1d_map"], filter_out_index="time", param_print=True)
            write_entity(db, ["commodity"], "commodity", "input/commodity.csv")
            write_entity(db, ["commodity__node"], "commodity,node", "input/commodity__node.csv")
            write_parameter(db, [("constraint", "sense")], "constraint,sense", "input/constraint__sense.csv")
            write_parameter(db, [("constraint", "constant")], "constraint,p_constraint_constant",
                            "input/p_constraint_constant.csv")
            write_parameter(db, [("model", "debug")], "debug", "input/debug.csv")
            write_entity(db, ["node", "unit", "connection"], "entity", "input/entity.csv")
            write_parameter(db, [("node", "invest_method"), ("unit", "invest_method"), ("connection", "invest_method")],
                            "entity,invest_method", "input/entity__invest_method.csv")
            write_parameter(db, [("node", "lifetime_method"), ("unit", "lifetime_method"),
                                 ("connection", "lifetime_method")], "entity,lifetime_method",
                            "input/entity__lifetime_method.csv")
            write_entity(db, ["group"], "group", "input/group.csv")
            write_parameter(db, [("group", "co2_method")], "group,co2_method", "input/group__co2_method.csv")
            write_parameter(db, [("group", "invest_method")], "group,invest_method", "input/group__invest_method.csv")
            write_parameter(db, [("group", "loss_share_type")], "group,loss_share_type",
                            "input/group__loss_share_type.csv")
            write_entity(db, ["group__node"], "group,node", "input/group__node.csv")
            write_entity(db, ["group__unit", "group__connection"], "group,process", "input/group__process.csv")
            write_entity(db, ["group__unit__node", "group__connection__node"], "group,process,node",
                         "input/group__process__node.csv")
            write_parameter(db, [("group", "has_capacity_margin")], "groupCapacityMargin",
                            "input/groupCapacityMargin.csv", filter_in_value="yes", no_value=True)
            write_parameter(db, [("group", "include_stochastics")], "group", "input/groupIncludeStochastics.csv",
                            filter_in_value="yes", no_value=True)
            write_parameter(db, [("group", "has_inertia")], "groupInertia", "input/groupInertia.csv",
                            filter_in_value="yes", no_value=True)
            write_parameter(db, [("group", "output_node_flows")], "groupOutputNodeFlows",
                            "input/groupOutputNodeFlows.csv", filter_in_value="yes", no_value=True)
            write_parameter(db, [("group", "output_aggregate_flows")], "groupOutputAggregateFlows",
                            "input/groupOutputAggregateFlows.csv", filter_in_value="yes", no_value=True)
            write_parameter(db, [("model", "exclude_entity_outputs")], "value", "input/exclude_entity_outputs.csv")
            write_parameter(db, [("model", "solves")], "model,solve", "input/model__solve.csv")
            write_entity(db, ["node"], "node", "input/node.csv")
            write_parameter(db, [("node", "constraint_capacity_coefficient")],
                            "node,constraint,p_node_constraint_capacity_coefficient",
                            "input/p_node_constraint_capacity_coefficient.csv")
            write_parameter(db, [("node", "constraint_state_coefficient")],
                            "node,constraint,p_node_constraint_state_coefficient",
                            "input/p_node_constraint_state_coefficient.csv")
            write_parameter(db, [("node", "has_balance")], "nodeBalance", "input/nodeBalance.csv",
                            filter_in_value="yes", no_value=True)
            write_parameter(db, [("node", "inflow_method")], "node,inflow_method", "input/node__inflow_method.csv")
            write_parameter(db, [("node", "node_type")], "node,node_type", "input/node__node_type.csv")
            write_parameter(db, [("node", "profile_method")], "node,profile,profile_method",
                            "input/node__profile__profile_method.csv")
            write_parameter(db, [("node", "has_storage")], "nodeState", "input/nodeState.csv", filter_in_value="yes",
                            no_value=True)
            write_parameter(db, [("node", "storage_binding_method")], "node,storage_binding_method",
                            "input/node__storage_binding_method.csv")
            write_parameter(db, [("node", "storage_nested_fix_method")], "node,storage_nested_fix_method",
                            "input/node__storage_nested_fix_method.csv")
            write_parameter(db, [("node", "storage_solve_horizon_method")], "node,storage_solve_horizon_method",
                            "input/node__storage_solve_horizon_method.csv")
            write_parameter(db, [("node", "storage_start_end_method")], "node,storage_start_end_method",
                            "input/node__storage_start_end_method.csv")
            write_parameter(db, [("node", "penalty_down"), ("node", "self_discharge_loss"), ("node", "availability"),
                                 ("node", "storage_state_reference_value")], "node,nodeParam,time,pt_node",
                            "input/pt_node.csv", filter_in_type=["1d_map", "array", "time_series"],
                            filter_out_index="period", param_print=True)
            write_parameter(db, [("node", "penalty_down"), ("node", "self_discharge_loss"), ("node", "availability"),
                                 ("node", "storage_state_reference_value")],
                            "node,nodeParam,branch,time_start,time,pt_node", "input/pbt_node.csv",
                            filter_in_type=["3d_map"], param_print=True)
            write_parameter(db, [("node", "inflow")], "node,time,pt_node_inflow", "input/pt_node_inflow.csv",
                            filter_in_type=["1d_map", "array", "time_series"], filter_out_index="period")
            write_parameter(db, [("node", "inflow")], "node,branch,time_start,time,pbt_node_inflow",
                            "input/pbt_node_inflow.csv", filter_in_type=["3d_map"])
            write_parameter(db, [("node", "annual_flow"),
                                 ("node", "peak_inflow"),
                                 ("node", "invest_forced"),
                                 ("node", "invest_max_period"),
                                 ("node", "invest_min_period"),
                                 ("node", "retire_forced"),
                                 ("node", "retire_max_period"),
                                 ("node", "retire_min_period"),
                                 ("node", "invest_cost"),
                                 ("node", "salvage_value"),
                                 ("node", "interest_rate"),
                                 ("node", "lifetime"),
                                 ("node", "fixed_cost"),
                                 ("node", "storage_state_reference_price"),
                                 ("node", "availability"),
                                 ("node", "penalty_up"),
                                 ("node", "penalty_down"),
                                 ("node", "cumulative_max_capacity"),
                                 ("node", "cumulative_min_capacity"),
                                 ("node", "self_discharge_loss"),
                                 ("node", "existing"),
                                 ("node", "storage_state_reference_value")], "node,nodeParam,period,pd_node",
                            "input/pd_node.csv", filter_in_type=["1d_map"], filter_out_index="time", param_print=True)
            write_entity(db, ["unit", "connection"], "process", "input/process.csv")
            write_entity(db, ["connection"], "process_connection", "input/process_connection.csv")
            write_parameter(db, [("unit__outputNode", "coefficient")], "process,sink,p_process_sink_coefficient",
                            "input/p_process_sink_coefficient.csv", filter_in_type=["float", "str", "bool"])
            write_parameter(db, [("unit__inputNode", "coefficient")], "process,source,p_process_source_coefficient",
                            "input/p_process_source_coefficient.csv", filter_in_type=["float", "str", "bool"])
            write_parameter(db, [("connection", "is_DC")], "process", "input/process_nonSync_connection.csv",
                            filter_in_value="yes", no_value=True)
            write_entity(db, ["unit"], "process_unit", "input/process_unit.csv")
            write_parameter(db, [("unit__outputNode", "other_operational_cost")], "process,sink,sourceSinkTimeParam,time,pt_process_sink",
                            "input/pt_process_sink.csv", filter_in_type=["1d_map"], filter_out_index="period", param_print=True)
            write_parameter(db, [("unit__outputNode", "other_operational_cost")], "process,sink,sourceSinkPeriodParam,period,pd_process_sink",
                            "input/pd_process_sink.csv", filter_in_type=["1d_map"], filter_out_index="time", param_print=True)
            write_parameter(db, [("unit__outputNode", "other_operational_cost")],
                            "process,sink,sourceSinkTimeParam,branch,time_start,time,pbt_process_sink", "input/pbt_process_sink.csv",
                            filter_in_type=["3d_map"], param_print=True)
            write_parameter(db, [("unit__inputNode", "other_operational_cost")],
                            "process,source,sourceSinkTimeParam,time,pt_process_source", "input/pt_process_source.csv",
                            filter_in_type=["1d_map"], filter_out_index="period", param_print=True)
            write_parameter(db, [("unit__inputNode", "other_operational_cost")],
                            "process,source,sourceSinkPeriodParam,period,pd_process_source", "input/pd_process_source.csv",
                            filter_in_type=["1d_map"], filter_out_index="time", param_print=True)
            write_parameter(db, [("unit__inputNode", "other_operational_cost")],
                            "process,source,sourceSinkTimeParam,branch,time_start,time,pbt_process_source", "input/pbt_process_source.csv",
                            filter_in_type=["3d_map"], param_print=True)
            write_parameter(db, [("connection__profile", "profile_method")], "process,profile,profile_method",
                            "input/process__profile__profile_method.csv")
            write_parameter(db, [("unit__outputNode", "ramp_method"), ("unit__inputNode", "ramp_method")],
                            "process,node,ramp_method", "input/process__node__ramp_method.csv")
            write_parameter(db, [("unit", "startup_method"), ("connection", "startup_method")],
                            "process,startup_method", "input/process__startup_method.csv")
            write_parameter(db, [("unit", "conversion_method"), ("connection", "transfer_method")], "process,ct_method",
                            "input/process__ct_method.csv")
            write_entity(db, ["reserve__upDown__unit__node", "reserve__upDown__connection__node"], "process,reserve,upDown,node",
                            "input/process__reserve__upDown__node.csv", entity_dimens=[[2,0,1,3], [2,0,1,3]])
            write_parameter(db, [("profile", "profile")], "profile,time,pt_profile", "input/pt_profile.csv",
                            filter_in_type=["1d_map"], filter_out_index="period")
            write_parameter(db, [("profile", "profile")], "profile,branch,time_start,time,pbt_profile", "input/pbt_profile.csv",
                            filter_in_type=["3d_map"])
            write_parameter(db, [("profile", "profile")], "profile,period,pd_profile", "input/pd_profile.csv",
                            filter_in_type=["1d_map"], filter_out_index="time")
            write_parameter(db, [("profile", "profile")], "profile,p_profile", "input/p_profile.csv",
                            filter_in_type=["float", "str", "bool"])
            write_entity(db, ["profile"], "profile", "input/profile.csv")
            write_parameter(db, [("reserve__upDown__group", "increase_reserve_ratio"),
                                 ("reserve__upDown__group", "penalty_reserve"),
                                 ("reserve__upDown__group", "reservation")],
                            "reserve,upDown,group,reserveParam,p_reserve_upDown_group",
                            "input/p_reserve__upDown__group.csv", filter_in_type=["float", "str", "bool"], param_print=True)
            write_parameter(db, [("reserve__upDown__group", "reservation")],
                            "reserve,upDown,group,reserveParam,time,pt_reserve_upDown_group",
                            "input/pt_reserve__upDown__group.csv", filter_in_type=["1d_map"], filter_out_index="period", param_print=True)
            write_parameter(db, [("reserve__upDown__group", "reservation")],
                            "reserve,upDown,group,reserveParam,branch,time_start,time,pbt_reserve_upDown_group",
                            "input/pbt_reserve__upDown__group.csv", filter_in_type=["3d_map"], param_print=True)
            write_parameter(db, [("reserve__upDown__group", "reserve_method")], "reserve,upDown,group,method",
                            "input/reserve__upDown__group__method.csv")
            write_parameter(db, [("solve", "solver")], "solve,solver", "input/solver.csv")
            write_parameter(db, [("solve", "timeline_hole_multiplier")], "solve,p_hole_multiplier",
                            "input/solve_hole_multiplier.csv")
            write_parameter(db, [("solve", "solver_precommand")], "solve,solver_precommand",
                            "input/solver_precommand.csv")
            write_parameter(db, [("solve", "solver_arguments")], "solve,arguments", "input/solver_arguments.csv")
            write_parameter(db, [("solve", "highs_method"),
                                 ("solve", "highs_parallel"),
                                 ("solve", "highs_presolve"),
                                 ("solve", "solve_mode")],
                            "param,solve,value", "input/solve_mode.csv", param_print=True, param_loc = 0)
            write_parameter(db, [("solve", "contains_solves")], "solve,include_solve",
                            "input/solve__contains_solve.csv")
            write_parameter(db, [("solve", "realized_periods")], "solve,roll,period",
                            "input/solve__realized_period_2d_map.csv", filter_in_type=["2d_map"], no_value=True)
            write_parameter(db, [("solve", "fix_storage_periods")], "solve,roll,period",
                            "input/solve__fix_storage_period_2d_map.csv", filter_in_type=["2d_map"], no_value=True)
            write_parameter(db, [("solve", "invest_periods")], "solve,roll,period",
                            "input/solve__invest_period_2d_map.csv", filter_in_type=["2d_map"], no_value=True)
            write_parameter(db, [("solve", "realized_periods")], "solve,period", "input/solve__realized_period.csv",
                            filter_in_type=["array", "1d_map"])
            write_parameter(db, [("solve", "realized_invest_periods")], "solve,invest_realized_period",
                            "input/solve__realized_invest_period.csv", filter_in_type=["array", "1d_map"])
            write_parameter(db, [("solve", "realized_invest_periods")], "solve,roll,period",
                            "input/solve__realized_invest_period_2d_map.csv", filter_in_type=["2d_map"], no_value=True)
            write_parameter(db, [("solve", "fix_storage_periods")], "solve,period",
                            "input/solve__fix_storage_period.csv", filter_in_type=["array", "1d_map"])
            write_parameter(db, [("solve", "invest_periods")], "solve,period", "input/solve__invest_period.csv",
                            filter_in_type=["array", "1d_map"])
            write_parameter(db, [("solve", "years_represented")], "solve,period,years_represented",
                            "input/solve__period__years_represented.csv")
            write_parameter(db, [("solve", "stochastic_branches")], "solve,period,branch,start_time,realized,weight",
                            "input/stochastic_branches.csv")
            write_parameter(db, [("timeline", "timestep_duration")], "timeline,timestep,duration", "input/timeline.csv")
            write_parameter(db, [("timeline", "timeline_duration_in_years")], "timeline,p_timeline_duration_in_years",
                            "input/timeline_duration_in_years.csv")
            write_parameter(db, [("timeblockSet", "block_duration")], "timeblocks,start,duration", "input/timeblocks.csv")
            write_entity(db, ["timeblockSet__timeline"], "timeblocks,timeline", "input/timeblocks__timeline.csv")
            write_parameter(db, [("solve", "period_timeblockSet")], "solve,roll,period,timeblocks",
                            "input/timeblocks_in_use_2d.csv", filter_in_type=["2d_map"])
            write_parameter(db, [("solve", "period_timeblockSet")], "solve,period,timeblocks", "input/timeblocks_in_use.csv",
                            filter_in_type=["1d_map"])
            write_parameter(db, [("timeblockSet", "new_stepduration")], "timeblockSet,step_duration",
                            "input/timeblockSet__new_stepduration.csv", filter_out_index="time")
            write_parameter(db, [("unit__outputNode")], "process,sink,param", "input/unit__sinkNode__param.csv",
                            filter_in_type=["1d_map"], filter_out_index="period", param_print=True)
            write_parameter(db, [("unit__inputNode")], "process,source,param", "input/unit__sourceNode__param.csv",
                            filter_out_index="period", param_print=True)
            write_parameter(db, [("unit", "efficiency"),
                                 ("unit", "efficiency_at_min_load"),
                                 ("unit", "min_load"),
                                 ("unit", "other_operational_cost"),
                                 ("unit", "availability"),
                                 ("connection", "efficiency"),
                                 ("connection", "efficiency_at_min_load"),
                                 ("connection", "min_load"),
                                 ("connection", "other_operational_cost"),
                                 ("connection", "availability"),
                                ],
                            "process,processParam,time,pt_process", "input/pt_process.csv", filter_in_type=["1d_map"],
                            filter_out_index="period", param_print=True)
            write_entity(db, ["unit__inputNode", "connection__node__node"], "process,source", "input/process__source.csv",
                         entity_dimens=[[0,1], [0,1]])
            write_parameter(db, [("unit__outputNode", "is_non_synchronous")], "process,sink",
                            "input/process__sink_nonSync_unit.csv", filter_in_value="yes", no_value=True)
            write_entity(db, ["unit__outputNode", "connection__node__node"], "process,sink", "input/process__sink.csv",
                         entity_dimens=[[0,1], [0,2]])
            write_parameter(db, [("unit__node__profile", "profile_method")], "process,node,profile,profile_method",
                            "input/process__node__profile__profile_method.csv")
            write_parameter(db, [("unit__inputNode")], "process,source,sourceSinkParam,p_process_source",
                            "input/p_process_source.csv", param_print=True)
            write_parameter(db, [("unit__outputNode")], "process,sink,sourceSinkParam,p_process_sink",
                            "input/p_process_sink.csv", param_print=True)
            write_parameter(db, [("reserve__upDown__unit__node", "increase_reserve_ratio"),
                                 ("reserve__upDown__unit__node", "large_failure_ratio"),
                                 ("reserve__upDown__unit__node", "max_share"),
                                 ("reserve__upDown__unit__node", "reliability"),
                                 ("reserve__upDown__connection__node", "increase_reserve_ratio"),
                                 ("reserve__upDown__connection__node", "large_failure_ratio"),
                                 ("reserve__upDown__connection__node", "max_share"),
                                 ("reserve__upDown__connection__node", "reliability")
                                 ],
                            "process,reserve,upDown,node,reserveParam,p_process_reserve_upDown_node",
                            "input/p_process__reserve__upDown__node.csv",
                            filter_in_type=["float", "str", "bool"], param_print=True, dimens = [1, 2, 0, 3])
            write_parameter(db, [("unit__outputNode", "constraint_flow_coefficient"),
                                 ("unit__inputNode", "constraint_flow_coefficient"),
                                 ("connection__node", "constraint_flow_coefficient")],
                            "process,node,constraint,p_process_node_constraint_flow_coefficient",
                            "input/p_process_node_constraint_flow_coefficient.csv", filter_in_type=["1d_map"])
            write_parameter(db, [("unit", "constraint_capacity_coefficient"),
                                 ("connection", "constraint_capacity_coefficient")],
                            "process,constraint,p_process_constraint_capacity_coefficient",
                            "input/p_process_constraint_capacity_coefficient.csv", filter_in_type=["1d_map"])
            write_parameter(db, [("unit", "availability"),
                                 ("unit", "cumulative_max_capacity"),
                                 ("unit", "cumulative_min_capacity"),
                                 ("unit", "efficiency"),
                                 ("unit", "efficiency_at_min_load"),
                                 ("unit", "existing"),
                                 ("unit", "fixed_cost"),
                                 ("unit", "interest_rate"),
                                 ("unit", "invest_cost"),
                                 ("unit", "invest_max_total"),
                                 ("unit", "invest_min_total"),
                                 ("unit", "lifetime"),
                                 ("unit", "min_downtime"),
                                 ("unit", "min_load"),
                                 ("unit", "min_uptime"),
                                 ("unit", "retire_max_total"),
                                 ("unit", "retire_min_total"),
                                 ("unit", "salvage_value"),
                                 ("unit", "startup_cost"),
                                 ("unit", "virtual_unitsize"),
                                 ("connection", "availability"),
                                 ("connection", "cumulative_max_capacity"),
                                 ("connection", "cumulative_min_capacity"),
                                 ("connection", "efficiency"),
                                 ("connection", "existing"),
                                 ("connection", "fixed_cost"),
                                 ("connection", "interest_rate"),
                                 ("connection", "invest_cost"),
                                 ("connection", "invest_max_total"),
                                 ("connection", "invest_min_total"),
                                 ("connection", "lifetime"),
                                 ("connection", "other_operational_cost"),
                                 ("connection", "retire_max_total"),
                                 ("connection", "retire_min_total"),
                                 ("connection", "salvage_value"),
                                 ("connection", "startup_cost"),
                                 ("connection", "virtual_unitsize")
                                ],
                            "process,processParam,p_process", "input/p_process.csv",
                            filter_in_type=["float", "str", "bool"], param_print=True)
            write_parameter(db, [("node", "annual_flow"),
                                 ("node", "availability"),
                                 ("node", "cumulative_max_capacity"),
                                 ("node", "cumulative_min_capacity"),
                                 ("node", "existing"),
                                 ("node", "fixed_cost"),
                                 ("node", "inflow"),
                                 ("node", "interest_rate"),
                                 ("node", "invest_cost"),
                                 ("node", "invest_forced"),
                                 ("node", "invest_max_total"),
                                 ("node", "invest_min_total"),
                                 ("node", "lifetime"),
                                 ("node", "peak_inflow"),
                                 ("node", "penalty_down"),
                                 ("node", "penalty_up"),
                                 ("node", "retire_max_total"),
                                 ("node", "retire_min_total"),
                                 ("node", "salvage_value"),
                                 ("node", "self_discharge_loss"),
                                 ("node", "storage_state_end"),
                                 ("node", "storage_state_reference_price"),
                                 ("node", "storage_state_reference_value"),
                                 ("node", "storage_state_start"),
                                 ("node", "storate_state_end"),
                                 ("node", "virtual_unitsize")
                                ], "node,nodeParam,p_node", "input/p_node.csv",
                            filter_in_type=["float", "str", "bool"], param_print=True)
            write_parameter(db, [("group__unit", "groupParam"), ("group__connection", "groupParam")],
                            "group,process,groupParam,p_group_process_s",
                            "input/p_group__process.csv", param_print=True)
            write_parameter(db, [("group", "groupParam"),
                                 ("group", "capacity_margin"),
                                 ("group", "co2_max_total"),
                                 ("group", "co2_price"),
                                 ("group", "inertia_limit"),
                                 ("group", "invest_max_total"),
                                 ("group", "invest_min_total"),
                                 ("group", "max_cumulative_flow"),
                                 ("group", "max_instant_flow"),
                                 ("group", "min_cumulative_flow"),
                                 ("group", "min_instant_flow"),
                                 ("group", "non_synchronous_limit"),
                                 ("group", "penalty_capacity_margin"),
                                 ("group", "penalty_inertia"),
                                 ("group", "penalty_non_synchronous"),
                                ], "group,groupParam,p_group", "input/p_group.csv",
                            filter_in_type=["float", "str", "bool"], param_print=True)
            write_parameter(db, [("unit", "invest_forced"),
                                 ("unit", "invest_max_period"),
                                 ("unit", "invest_min_period"),
                                 ("unit", "retire_forced"),
                                 ("unit", "retire_max_period"),
                                 ("unit", "retire_min_period"),
                                 ("unit", "invest_cost"),
                                 ("unit", "salvage_value"),
                                 ("unit", "interest_rate"),
                                 ("unit", "lifetime"),
                                 ("unit", "fixed_cost"),
                                 ("unit", "other_operational_cost"),
                                 ("unit", "existing"),
                                 ("unit", "cumulative_max_capacity"),
                                 ("unit", "cumulative_min_capacity"),
                                 ("connection", "invest_forced"),
                                 ("connection", "invest_max_period"),
                                 ("connection", "invest_min_period"),
                                 ("connection", "retire_forced"),
                                 ("connection", "retire_max_period"),
                                 ("connection", "retire_min_period"),
                                 ("connection", "invest_cost"),
                                 ("connection", "salvage_value"),
                                 ("connection", "interest_rate"),
                                 ("connection", "lifetime"),
                                 ("connection", "fixed_cost"),
                                 ("connection", "other_operational_cost"),
                                 ("connection", "existing"),
                                 ("connection", "cumulative_max_capacity"),
                                 ("connection", "cumulative_min_capacity"),
                                ],
                            "process,processParam,period,pd_process", "input/pd_process.csv", filter_in_type=["1d_map"],
                            filter_out_index="time", param_print=True)
            write_parameter(db, [("model", "discount_rate")], "model,p_discount_rate", "input/p_discount_rate.csv")
            write_parameter(db, [("model", "discount_offset_operations")], "model,p_discount_offset_operations",
                            "input/p_discount_offset_operations.csv")
            write_parameter(db, [("model", "discount_offset_investment")], "model,p_discount_offset_investment",
                            "input/p_discount_offset_investment.csv")
            write_parameter(db, [("group", "co2_max_period"),
                                 ("group", "co2_price"),
                                 ("group", "inertia_limit"),
                                 ("group", "invest_max_period"),
                                 ("group", "invest_min_period"),
                                 ("group", "invest_min_total"),
                                 ("group", "max_cumulative_flow"),
                                 ("group", "max_instant_flow"),
                                 ("group", "min_cumulative_flow"),
                                 ("group", "min_instant_flow"),
                                 ("group", "non_synchronous_limit"),
                                 ("group", "penalty_capacity_margin"),
                                 ("group", "penalty_inertia"),
                                 ("group", "penalty_non_synchronous"),
                                 ], "group,groupParam,period,pd_group", "input/pd_group.csv",
                            filter_in_type=["1d_map"], filter_out_index="time", param_print=True)
            write_parameter(db, [("group", "co2_price"),
                                 ("group", "max_instant_flow"),
                                 ("group", "min_instant_flow"),
                                ], "group,groupParam,time,pt_group", "input/pt_group.csv",
                            filter_in_type=["1d_map"], filter_out_index="period", param_print=True)
            write_parameter(db, [("unit", "efficiency"),
                                 ("unit", "efficiency_at_min_load"),
                                 ("unit", "min_load"),
                                 ("unit", "other_operational_cost"),
                                 ("unit", "availability"),
                                 ("connection", "efficiency"),
                                 ("connection", "efficiency_at_min_load"),
                                 ("connection", "min_load"),
                                 ("connection", "other_operational_cost"),
                                 ("connection", "availability")
                                ],
                            "process,processParam,branch,time_start,time,pbt_process", "input/pbt_process.csv",
                            filter_in_type=["3d_map"], param_print=True)
            write_parameter(db, [("model", "exclude_entity_outputs"),
                                 ("model", "output_connection__node__node_flow_t"),
                                 ("model", "output_connection_flow_separate"),
                                 ("model", "output_horizon"),
                                 ("model", "output_ramp_envelope"),
                                 ("model", "output_unit__node_flow_t"),
                                 ("model", "output_unit__node_ramp_t"),
                                ], "output,value", "input/optional_outputs.csv", param_print=True, no_entity=True)
            write_parameter(db, [("group", "output_results")], "groupOutput", "input/groupOutput.csv",
                            filter_in_value="yes", no_value=True)
            write_parameter(db, [("group", "has_non_synchronous")], "groupNonSync", "input/groupNonSync.csv",
                            filter_in_value="yes", no_value=True)
            write_default_values(db, [("model", "version")], "version", "input/db_version.csv",
                            filter_in_type=["float", "str", "bool"], only_value=True)



def write_entity(db, cl, header, filename, entity_dimens=None):
    entities = []
    for (i, ent_class) in enumerate(cl):
        class_entity_dimens = None
        if entity_dimens:
            class_entity_dimens = entity_dimens[i]
        for entity in db.get_entity_items(entity_class_name=ent_class):
            if class_entity_dimens is None:
                entities.append(','.join(entity["entity_byname"]))
            else:
                entity_dim = []
                for x in class_entity_dimens:
                    entity_dim.append(entity["entity_byname"][x])
                entities.append(','.join(entity_dim))


    with open(filename, 'w') as realfile:
        realfile.write(header + "\n")
        for entity in entities:
            realfile.write(entity + "\n")


def write_parameter(db, cl_pars, header, filename,
                    filter_in_type=None, filter_out_index=None, filter_in_value=None,
                    no_value=False, param_print=False, dimens=None, param_loc=None, no_entity=None):
    # interpret map dimensionality and map into map for later comparisons
    print(f'writing: {cl_pars}')
    type_filter_map_dim = []
    if filter_in_type:
        map_found = False
        for type_filter in filter_in_type:
            if type_filter in ["1d_map", "2d_map", "3d_map", "4d_map", "5d_map"]:
                if map_found:
                    logging.error("Trying to have two different dimensionalities in the same parameter to be written out")
                    sys.exit(-1)
                map_found = True
                type_filter_map_dim = int(type_filter[0])
                filter_in_type.remove(type_filter)
        if map_found:
            filter_in_type.append("map")
    params = []
    for cl_par in cl_pars:
        params = params + db.get_parameter_value_items(entity_class_name=cl_par[0],
                                                       parameter_definition_name=cl_par[1])
    with open(filename, 'w') as realfile:
        realfile.write(header + "\n")
        for param in params:
            # This filter ensures that the parameter is of required type (skip to next if not)
            if filter_in_type and param["type"] not in filter_in_type:
                continue

            entity_byname = param["entity_byname"]
            if dimens:
                temp_entity_byname = [None] * len(entity_byname)
                for i, dimen in enumerate(dimens):
                    temp_entity_byname[dimen] = entity_byname[i]
                entity_byname = temp_entity_byname


            if param_print:
                if param_loc is not None:
                    time.sleep(0.1)
                    collect = []
                    for (i, byname) in enumerate(entity_byname):
                        if i == param_loc:
                            collect.append(param["parameter_definition_name"])
                        collect.append(byname)
                    first_cols = ','.join(collect)
                else:
                    if no_entity:
                        first_cols = param["parameter_definition_name"]
                    else:
                        first_cols = ','.join(entity_byname) + ',' + param["parameter_definition_name"]
            else:
                first_cols = ','.join(entity_byname)
            if param["type"] == "map":
                # If the first parameter index contains filter_out_index, then skip the parameter (maybe should be extended to other indexes)
                if filter_out_index and param["parsed_value"].index_name == filter_out_index:
                    continue
                # Check that map dimensionality matches with filter requirement (if not, then skip)
                if filter_in_type and type_filter_map_dim != api.parameter_value.from_database_to_dimension_count(param["value"], param["type"]):
                    continue
                value = param["parsed_value"]
                indexes = []
                if api.parameter_value.from_database_to_dimension_count(param["value"], param["type"]) <= 1:
                    result = list(value.indexes)
                    # Doing a zip, since there can be multiple rows in the map
                    result = list(zip(result, [str(v) for v in value.values]))
                    for res in result:
                        if no_value:
                            realfile.write(first_cols + ',' + res[0] + '\n')
                        else:
                            realfile.write(first_cols + ',' + ','.join(res) + '\n')
                else:
                    flat_map = api.convert_map_to_table(value)
                    for (i, index) in enumerate(flat_map):
                        if no_value:
                            realfile.write(first_cols + ',' + ','.join(index[:-1]) + '\n')
                        else:
                            index[-1] = str(index[-1])
                            realfile.write(first_cols + ',' + ','.join(index) + '\n')
            elif param["type"] == "array" or param["type"] == "time_series":
                for row in param["parsed_value"].values:
                    realfile.write(','.join(entity_byname) + ',' + row + '\n')
            elif param["type"] == "str" or param["type"] == "float" or param["type"] == "bool":
                # Filter based on values: only if the value is found, then data is written
                if filter_in_value and param["parsed_value"] != filter_in_value:
                    continue
                if no_value:
                    realfile.write(first_cols + '\n')
                else:
                    realfile.write(first_cols + ',' + str(param["parsed_value"]) + '\n')
            else:
                if not filter_in_type:
                    filter_in_type = ["bool", "str", "float", "array", "time_series", "map"]
                logging.error(f"Input data found in a parameter not of supported type."+ 
                              f"\nEntity: {','.join(entity_byname)}"+
                              f"\nParameter: {param['parameter_definition_name']}"+
                              f"\nSupported types: {filter_in_type}"+
                              f"\nParameter type: {param['type']}")
                sys.exit(-1)


def flatten_map(mapList, indexes):
    result = []
    j = 0
    for (i, subMap) in enumerate(mapList):
        parent_index = indexes.pop(i + j)
        for (k, child_index) in enumerate(list(subMap.indexes)):
            comb_index = copy.deepcopy(parent_index)
            comb_index.extend([child_index])
            indexes.insert(i + j, comb_index)
            if any(isinstance(x, api.Map) for x in subMap.values):
                (result, indexes) = flatten_map(subMap.values, [indexes[i + j]])
            else:
                result.append(subMap.values[k])
            j = j + 1
        # del indexes[i + j]
        j = j - 1
    return (result, indexes)


def write_default_values(db, cl_pars, header, filename, filter_in_type=None, only_value=False):
    param_defs = []
    for cl_par in cl_pars:
        param_defs.append(db.get_parameter_definition_item(entity_class_name=cl_par[0],
                                                           name=cl_par[1]))
    with open(filename, 'w') as realfile:
        realfile.write(header + "\n")
        for param in param_defs:
            # This filter ensures that the parameter is of required type (skip to next if not)
            if filter_in_type and param["default_type"] not in filter_in_type:
                continue

            if param["default_type"] == "str" or param["default_type"] == "float" or param["default_type"] == "bool":
                if only_value:
                    realfile.write(str(api.from_database(param["default_value"], param["default_type"])) + '\n')
                else:
                    realfile.write(param["entity_class_name"] + "," + param["name"] + ","
                               + str(api.from_database(param["default_value"], param["default_type"])) + '\n')
            else:
                logging.error("Default_value found in a parameter definition not of supported default type"+
                              "\nParameter: " + param["parameter_definition_name"])
                sys.exit(-1)


def main():
    logging.basicConfig(level=logging.INFO)
    logging.error("Run using run_flextool.py in the root of FlexTool")
    sys.exit(-1)

if __name__ == '__main__':
    main()
