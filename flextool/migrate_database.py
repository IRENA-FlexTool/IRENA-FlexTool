import json
import os
import argparse
from spinedb_api import import_data, DatabaseMapping, from_database, SpineDBAPIError


def migrate_database(database_path):

    if not os.path.exists(database_path) or not database_path.endswith(".sqlite"):
        print("No sqlite file at " + database_path)
        exit(-1)

    with DatabaseMapping('sqlite:///' + database_path, create = False, upgrade = True) as db:
        sq= db.object_parameter_definition_sq
        settings_parameter = db.query(sq).filter(sq.c.object_class_name == "model").filter(sq.c.parameter_name == "version").one_or_none()
        if settings_parameter is None:
            #if no version assume version 0
            print("No version found. Assuming version 0, if older, migration might not work")
            version = 0
        else:
            version = from_database(settings_parameter.default_value, settings_parameter.default_type)

        next_version = int(version) + 1
        new_version = 23

        while next_version <= new_version:
            if next_version == 0:
                add_version(db)
            elif next_version == 1:
                add_new_parameters(db, './version/flextool_template_v2.json')
            elif next_version == 2:
                add_new_parameters(db, './version/flextool_template_rolling_window.json')
            elif next_version == 3:
                add_new_parameters(db, './version/flextool_template_lifetime_method.json')
            elif next_version == 4:
                add_new_parameters(db, './version/flextool_template_drop_down.json')
            elif next_version == 5:
                add_new_parameters(db, './version/flextool_template_optional_outputs.json')
            elif next_version == 6:
                add_new_parameters(db, './version/flextool_template_default_value.json')
            elif next_version == 7:
                add_new_parameters(db, './version/flextool_template_rolling_start_remove.json')
            elif next_version == 8:
                add_new_parameters(db, './version/flextool_template_output_node_flows.json')
            elif next_version == 9:
                add_new_parameters(db, './version/flextool_template_constant_default.json')
            elif next_version == 10:
                add_new_parameters(db, './version/flextool_template_storage_binding_defaults.json')
            elif next_version == 11:
                change_optional_output_type(db,'./version/flextool_template_default_optional_output.json')
            elif next_version == 12:
                new_parameters = [["group", "output_aggregate_flows", None, "output_node_flows", "Used with group_unit_node or group_connection_node to combine the flows when producing the output_node_flows of a node group."],
                                  ["group", "output_node_flows", None, "output_node_flows" ,"Creates the timewise flow output for this node group (group_flow_t)"]]
                add_parameters_manual(db,new_parameters)
                remove_parameters_manual(db,[["solve","rolling_start_time"]])
            elif next_version == 13:
                new_value_list = [["load_share_type","equal"],["load_share_type","inflow_weighted"],["load_share_type","no"]]
                new_parameters = [["group", "share_loss_of_load", "no", "load_share_type", "Force the upward slack of the nodes in this group to be equal or inflow (demand) weighted"]]
                #value list needs to be added first
                add_value_list_manual(db,new_value_list)
                add_parameters_manual(db,new_parameters)
                remove_parameters_manual(db,[["node","storate_state_end"]])
            elif next_version == 14:
                new_parameters = [["model","exclude_entity_outputs", "yes", "optional_output", "Excludes results on node, unit and connection level, but preserves group level results"]]
                remove_parameters_manual(db, [["model","results"]])
                add_parameters_manual(db, new_parameters)
            elif next_version == 15:
                remove_parameters_manual(db,[["unit", "invest_forced"], ["unit", "retire_forced"], ["connection", "invest_forced"], ["connection", "retire_forced"],
                                             ["node", "invest_forced"], ["node", "retire_forced"]])
                add_parameters_manual(db, [["group", "co2_max_period", "no_method", "co2_methods", "[tCO2] Annualized maximum limit for emitted CO2 in each period."]])
            elif next_version == 16:
                add_parameters_manual(db, [["group", "co2_max_period", None, None, "[tCO2] Annualized maximum limit for emitted CO2 in each period."]])
            elif next_version == 17:
                add_value_list_manual(db,[["yes_no", "yes"], ["yes_no", "no"]])
                new_parameters = [["solve", "stochastic_branches", None, None, "[4d-Map], Sets branches included in the solve. [Period, branch, start_time (time_step), realized (yes/no), weight (number)]. Only one of the branches should be realized for each start_time"],
                                  ["group", "include_stochastics", "no", "yes_no", "Includes the stochastic branches to be used for the nodes/units/connections in this group"],
                                  ["model", "output_horizon", "no", "yes_no", "Outputs the flows in the horizons. Used for testing the model."]]
                add_parameters_manual(db,new_parameters)
            elif next_version == 18:
                new_parameters = [["group", "penalty_inertia", 5000, None, "[CUR/MWs] Penalty for violating the inertia constraint. Constant or period."],
                                  ["group", "penalty_capacity_margin", 5000, None, "[CUR/MWh] Penalty for violating the capacity margin constraint. Constant or period."],
                                  ["group", "penalty_non_synchronous", 5000, None, "[CUR/MWh] Penalty for violating the non synchronous constraint. Constant or period."]]
                new_relationships = [["reserve__upDown__group", "penalty_reserve", 5000, None, "[CUR/MW] Penalty for violating a reserve constraint. Constant."]]
                add_parameters_manual(db,new_parameters)
                add_relationships_manual(db,new_relationships)
            elif next_version == 19:
                remove_parameters_manual(db, [["constraint", "is_active"], ["reserve__upDown__unit__node", "is_active"]])
            elif next_version == 20:
                remove_parameters_manual(db, [["connection", "is_active"], ["node", "is_active"], ["unit", "is_active"], ["reserve__upDown__connection", "is_active"]])
            elif next_version == 21:
                new_value_list = [["storage_nested_fix_method","fix_nothing"],["storage_nested_fix_method","fix_quantity"],["storage_nested_fix_method","fix_price"], ["storage_nested_fix_method","fix_usage"]]
                add_value_list_manual(db,new_value_list)
            elif next_version == 22:
                db.add_update_item("parameter_value_list", name = "node_type")
                add_value_list_manual(db,[["node_type","balance_within_period"],["invest_methods","cumulative_limits"]])
                db.add_update_item("parameter_definition", entity_class_name= "node", name= "node_type", parameter_type_list = None, parameter_value_list_name = "node_type", description = "Selection for the node to have period balance, instead of time step balance.")
                db.add_update_item("parameter_definition", entity_class_name= "node", name= "cumulative_max_capacity", parameter_type_list = None, description = "[MWh] Maximum cumulative capacity (considers existing, invested and retired capacity). Constant or period.")
                db.add_update_item("parameter_definition", entity_class_name= "node", name= "cumulative_min_capacity", parameter_type_list = None, description = "[MWh] Minimum cumulative capacity (considers existing, invested and retired capacity). Constant or period.")
                db.add_update_item("parameter_definition", entity_class_name= "connection", name= "cumulative_max_capacity", parameter_type_list = None, description = "[MW] Maximum cumulative capacity (considers existing, invested and retired capacity). Constant or period.")
                db.add_update_item("parameter_definition", entity_class_name= "connection", name= "cumulative_min_capacity", parameter_type_list = None, description = "[MW] Minimum cumulative capacity (considers existing, invested and retired capacity). Constant or period.")
                db.add_update_item("parameter_definition", entity_class_name= "unit", name= "cumulative_max_capacity", parameter_type_list = None, description = "[MW] Maximum cumulative capacity (considers existing, invested and retired capacity). Constant or period.")
                db.add_update_item("parameter_definition", entity_class_name= "unit", name= "cumulative_min_capacity", parameter_type_list = None, description = "[MW] Minimum cumulative capacity (considers existing, invested and retired capacity). Constant or period.")
                db.update_item("parameter_definition", entity_class_name= "node", name= "existing", description = "[MWh] Existing storage capacity. Constant or Period")
                db.update_item("parameter_definition", entity_class_name= "connection", name= "existing", description = "[MW] Existing capacity. Constant or Period")
                db.update_item("parameter_definition", entity_class_name= "unit", name= "existing", description = "[MW] Existing capacity. Constant or Period")
                db.update_item("parameter_definition", entity_class_name= "node", name= "penalty_up", description = "[CUR/MW] Penalty cost for decreasing consumption in the node. Constant, Period or Time.")
                db.update_item("parameter_definition", entity_class_name= "node", name= "penalty_down", description = "[CUR/MW] Penalty cost for increasing consumption in the node. Constant, Period or Time.")
                db.update_item("parameter_definition", entity_class_name= "unit__outputNode", name= "other_operational_cost", description = "[CUR/MWh] Other operational variable cost for energy flows. Constant, Period or Time.")
                db.update_item("parameter_definition", entity_class_name= "unit__inputNode", name= "other_operational_cost", description = "[CUR/MWh] Other operational variable cost for energy flows. Constant, Period or Time.")
                db.update_item("parameter_definition", entity_class_name= "connection", name= "other_operational_cost", description = "[CUR/MWh] Other operational variable cost for trasferring over the connection. Constant, Period or time.")
                db.update_item("parameter_definition", entity_class_name= "solve", name= "solve_mode", description = "A single_solve or rolling_window for a set of rolling optimisation windows solved in a sequence.")
                db.commit_session("Added cumulative investments")
            elif next_version == 23:
                db.add_update_item("parameter_definition", entity_class_name= "commodity", name= "price", parameter_type_list = None, parameter_value_list_name = None, description = "[CUR/MWh or other unit] Price of the commodity. Constant, period or time.")
                db.add_update_item("parameter_definition", entity_class_name= "group", name= "co2_price", parameter_type_list = None, parameter_value_list_name = None, description = "[CUR/ton] CO2 price for a group of nodes. Constant, period or time.")
                update_parameter_types(db)
            else:
                print("Version invalid")
            next_version += 1

        if version < new_version:
            version_up = [["model", "version", new_version, None, "Contains database version information."]]
            (num,log) = import_data(db, object_parameters = version_up)
            print(database_path+ " updated to version "+ str(new_version))
            db.commit_session("Updated Flextool data structure to version " + str(new_version))
        else:
            print(database_path+ " already up-to-date at version "+ str(version))

def add_version(db):
    # this function adds the version information to the database if there is none

    version_up = [["model", "version", 1, None, "Contains database version information."]]
    (num,log) = import_data(db, object_parameters = version_up)
    db.commit_session("Added version parameter")

    return 0

def remove_parameters_manual(db,obj_param_names):
    sq_def = db.object_parameter_definition_sq
    id_list = []
    for name_list in obj_param_names:
        object_name = name_list[0]
        parameter_name = name_list[1]
        param = db.query(sq_def).filter(sq_def.c.object_class_name == object_name).filter(sq_def.c.parameter_name == parameter_name).one_or_none()
        if param != None:
            id_list.append(param.id)

    try:
        db.remove_items('parameter_definition', *id_list)
        db.commit_session("Removed parameters")
    except SpineDBAPIError:
        print("This removal has been done before, continuing")
    return 0

def add_parameters_manual(db,new_parameters):
    (num,log) = import_data(db, object_parameters = new_parameters)
    try:
        db.commit_session("Added new parameters")
    except SpineDBAPIError:
        print("These parameters have been added before, continuing") 
    return 0

def add_relationships_manual(db, new_relationships):
    (num,log) = import_data(db, relationship_parameters = new_relationships)
    try:
        db.commit_session("Added new parameters")
    except SpineDBAPIError:
        print("These parameters have been added before, continuing") 
    return 0

def add_value_list_manual(db, new_value_lists):
    (num,log) = import_data(db,parameter_value_lists = new_value_lists)
    try:
        db.commit_session("Added new parameter value lists")
    except SpineDBAPIError:
        print("These value lists have been added before, continuing")
    return 0

def add_new_parameters(db, filepath):

    #get template JSON. This can be the master or old template if conflicting migrations in between
    with open(filepath) as json_file:
        template = json.load(json_file)

    #Parameter values need to be added first! Otherwise the new value_list_name cannot be connected!
    #Add parameter_value_lists. Note that object_parameter import and value_list import work differently. Former replaces all, latter adds what is missing.
    (num,log) = import_data(db, parameter_value_lists = template["parameter_value_lists"])

    #With objective parameters, no duplicates are created. These will replace the old ones or create new. There will always be imports.
    (num,log) = import_data(db, object_parameters = template["object_parameters"])

    try:
        db.commit_session("Added new parameters")
    except SpineDBAPIError:
        print("These parameters have been added before, continuing") 
    return 0

def change_optional_output_type(db, filepath):

    sq= db.entity_parameter_value_sq
    sq_def = db.object_parameter_definition_sq
    enable_parameter_query = db.query(sq).filter(sq.c.object_class_name == "model").filter(sq.c.parameter_name == "enable_optional_outputs")
    disable_parameter_query = db.query(sq).filter(sq.c.object_class_name == "model").filter(sq.c.parameter_name == "disable_optional_outputs")
    enable_parameter_definition =  db.query(sq_def).filter(sq_def.c.object_class_name == "model").filter(sq_def.c.parameter_name == "enable_optional_outputs").one_or_none()
    disable_parameter_definition =  db.query(sq_def).filter(sq_def.c.object_class_name == "model").filter(sq_def.c.parameter_name == "disable_optional_outputs").one_or_none()

    paramset_enable = []
    paramset_disable = []
    for param in enable_parameter_query:
        enable_optional_outputs = from_database(param.value, param.type).values
        meta = [param.entity_class_name, param.entity_name, param.alternative_name]
        paramset_enable.append((meta,enable_optional_outputs))

    for param in disable_parameter_query:
        disable_optional_outputs = from_database(param.value, param.type).values
        meta = [param.entity_class_name, param.entity_name, param.alternative_name]
        paramset_disable.append((meta,disable_optional_outputs))

    add_new_parameters(db, filepath)

    for param in paramset_enable:
        for output_name in param[1]:
            if output_name == 'ramp_envelope':
                parameter_name = 'output_ramp_envelope'
            elif output_name == 'unit__node_ramp_t':
                parameter_name = 'output_unit__node_ramp_t'
            elif output_name == 'connection_flow_separate' or output_name == 'connection_flow_one_direction':
                parameter_name = 'output_connection_flow_separate'
            else:
                parameter_name = 'invalid'
            if parameter_name != 'invalid':
                new_output = [(param[0][0], param[0][1], parameter_name, "yes", param[0][2])]
                (num,log) = import_data(db, object_parameter_values = new_output)
    for param in paramset_disable:
        for output_name in param[1]:
            if output_name == 'unit_flow_t' or output_name == 'unit__node_flow_t':
                parameter_name = 'output_unit__node_flow_t'
            elif output_name == 'connection_flow_t' or output_name == 'connection__node__node_flow_t':
                parameter_name = 'output_connection__node__node_flow_t'
            else:
                parameter_name = 'invalid'
            if parameter_name != 'invalid':
                new_output = [(param[0][0], param[0][1], parameter_name, "no", param[0][2])]
                (num,log) = import_data(db, object_parameter_values = new_output)
    
    if enable_parameter_definition != None:
        db.remove_items('parameter_definition', *[enable_parameter_definition.id,disable_parameter_definition.id])
    try:
        db.commit_session("Changed optional outputs")
    except SpineDBAPIError:
        print("This change has been done before, continuing") 
    return 0

def update_parameter_types(db):
    type_list = get_parameter_type_list()
    for i in type_list:
        db.add_update_item("parameter_definition", entity_class_name = i[0], name = i[1], parameter_type_list = i[2])

def get_parameter_type_list():
    types = [["commodity", "co2_content", ("float",)],
             ["commodity", "price", ("float","1d_map")],
             ["connection", "availability", ("float","1d_map")],
             ["connection", "constraint_capacity_coefficient", ("1d_map",)],
             ["connection", "cumulative_max_capacity", ("float","1d_map")],
             ["connection", "cumulative_min_capacity", ("float","1d_map")],
             ["connection", "efficiency", ("float","1d_map")],
             ["connection", "existing", ("float","1d_map")],
             ["connection", "fixed_cost", ("float","1d_map")],
             ["connection", "interest_rate", ("float","1d_map")],
             ["connection", "invest_cost", ("float","1d_map")],
             ["connection", "invest_max_period", ("1d_map",)],
             ["connection", "invest_max_total", ("float",)],
             ["connection", "invest_method", ("str",)],
             ["connection", "invest_min_period", ("1d_map",)],
             ["connection", "invest_min_total", ("float",)],
             ["connection", "is_DC", ("str",)],
             ["connection", "lifetime", ("float","1d_map")],
             ["connection", "lifetime_method", ("str",)],
             ["connection", "other_operational_cost", ("float","1d_map")],
             ["connection", "retire_max_period", ("1d_map",)],
             ["connection", "retire_max_total", ("float",)],
             ["connection", "retire_min_period", ("1d_map",)],
             ["connection", "retire_min_total", ("float",)],
             ["connection", "salvage_value", ("float","1d_map")],
             ["connection", "startup_cost", ("float",)],
             ["connection", "startup_method", ("str",)],
             ["connection", "transfer_method", ("str",)],
             ["connection", "virtual_unitsize", ("float",)],
             ["constraint", "constant", ("float",)],
             ["constraint", "sense", ("str",)],
             ["group", "capacity_margin", ("float","1d_map")],
             ["group", "co2_max_period", ("1d_map",)],
             ["group", "co2_max_total", ("float",)],
             ["group", "co2_method", ("str",)],
             ["group", "co2_price", ("float","1d_map")],
             ["group", "has_capacity_margin", ("str",)],
             ["group", "has_inertia", ("str",)],
             ["group", "has_non_synchronous", ("str",)],
             ["group", "include_stochastics", ("str",)],
             ["group", "inertia_limit", ("float","1d_map")],
             ["group", "invest_max_period", ("1d_map",)],
             ["group", "invest_max_total", ("float",)],
             ["group", "invest_method", ("str",)],
             ["group", "invest_min_period", ("1d_map",)],
             ["group", "invest_min_total", ("float",)],
             ["group", "max_cumulative_flow", ("float","1d_map")],
             ["group", "max_instant_flow", ("float","1d_map")],
             ["group", "min_cumulative_flow", ("float","1d_map")],
             ["group", "min_instant_flow", ("float","1d_map")],
             ["group", "non_synchronous_limit", ("float","1d_map")],
             ["group", "output_aggregate_flows",  ("str",)],
             ["group", "output_node_flows", ("str",)],
             ["group", "output_results", ("str",)],
             ["group", "penalty_capacity_margin", ("float","1d_map")],
             ["group", "penalty_inertia", ("float","1d_map")],
             ["group", "penalty_non_synchronous", ("float","1d_map")],
             ["group", "share_loss_of_load", ("str",)],
             ["model", "debug", ("str",)],
             ["model", "discount_offset_investment", ("float",)],
             ["model", "discount_offset_operations", ("float",)],
             ["model", "discount_rate", ("float",)],
             ["model", "exclude_entity_outputs", ("str",)],
             ["model", "output_connection__node__node_flow_t", ("str",)],
             ["model", "output_connection_flow_separate", ("str",)],
             ["model", "output_horizon", ("str",)],
             ["model", "output_node_balance_t", ("str",)],
             ["model", "output_ramp_envelope", ("str",)],
             ["model", "output_unit__node_flow_t", ("str",)],
             ["model", "output_unit__node_ramp_t", ("str",)],
             ["model", "solves", ("array",)],
             ["model", "version", ("float",)],
             ["node", "annual_flow", ("float","1d_map")],
             ["node", "availability", ("float","1d_map","3d_map")],
             ["node", "constraint_capacity_coefficient", ("1d_map",)],
             ["node", "constraint_state_coefficient", ("1d_map",)],
             ["node", "cumulative_max_capacity", ("float","1d_map")],
             ["node", "cumulative_min_capacity", ("float","1d_map")],
             ["node", "existing", ("float","1d_map")],
             ["node", "fixed_cost", ("float","1d_map")],
             ["node", "has_balance", ("str",)],
             ["node", "has_storage", ("str",)],
             ["node", "inflow", ("float","1d_map","3d_map")],
             ["node", "inflow_method", ("str",)],
             ["node", "interest_rate", ("float","1d_map")],
             ["node", "invest_cost", ("float","1d_map")],
             ["node", "invest_forced", ("float","1d_map")],
             ["node", "invest_max_period", ("1d_map",)],
             ["node", "invest_max_total", ("float",)],
             ["node", "invest_method", ("str",)],
             ["node", "invest_min_period", ("1d_map",)],
             ["node", "invest_min_total", ("float",)],
             ["node", "lifetime", ("float","1d_map")],
             ["node", "lifetime_method", ("str",)],
             ["node", "node_type", ("str",)],
             ["node", "peak_inflow", ("float","1d_map")],
             ["node", "penalty_down", ("float","1d_map")],
             ["node", "penalty_up", ("float","1d_map")],
             ["node", "retire_max_period", ("1d_map",)],
             ["node", "retire_max_total", ("float",)],
             ["node", "retire_min_period", ("1d_map",)],
             ["node", "retire_min_total", ("float",)],
             ["node", "salvage_value",  ("float","1d_map")],
             ["node", "self_discharge_loss", ("float","1d_map")],
             ["node", "storage_binding_method", ("str",)],
             ["node", "storage_nested_fix_method", ("str",)],
             ["node", "storage_solve_horizon_method", ("str",)],
             ["node", "storage_start_end_method", ("str",)],
             ["node", "storage_state_end", ("float",)],
             ["node", "storage_state_reference_price", ("float","1d_map")],
             ["node", "storage_state_reference_value", ("float","1d_map")],
             ["node", "storage_state_start", ("float",)],
             ["node", "storate_state_end", ("float",)],
             ["node", "virtual_unitsize", ("float",)],
             ["profile", "profile", ("1d_map","3d_map")],
             ["solve", "contains_solves", ("array",)],
             ["solve", "fix_storage_periods", ("array","2d_map")],
             ["solve", "highs_method", ("str",)],
             ["solve", "highs_parallel", ("str",)],
             ["solve", "highs_presolve", ("str",)],
             ["solve", "invest_periods", ("array","2d_map")],
             ["solve", "period_timeblockSet", ("1d_map",)],
             ["solve", "realized_invest_periods", ("array","2d_map")],
             ["solve", "realized_periods", ("array","2d_map")],
             ["solve", "rolling_duration", ("float",)],
             ["solve", "rolling_solve_horizon", ("float",)],
             ["solve", "rolling_solve_jump", ("float",)],
             ["solve", "solve_mode", ("str",)],
             ["solve", "solver", ("str",)],
             ["solve", "solver_arguments", ("array",)],
             ["solve", "solver_precommand", ("str",)],
             ["solve", "stochastic_branches", ("4d_map",)],
             ["solve", "years_represented", ("1d_map",)],
             ["timeblockSet", "block_duration", ("1d_map",)],
             ["timeblockSet", "new_stepduration", ("float",)],
             ["timeline", "timeline_duration_in_years", ("float",)],
             ["timeline", "timestep_duration", ("1d_map",)],
             ["unit", "availability", ("float","1d_map","3d_map")],
             ["unit", "constraint_capacity_coefficient", ("1d_map",)],
             ["unit", "conversion_method", ("str",)],
             ["unit", "cumulative_max_capacity", ("float","1d_map")],
             ["unit", "cumulative_min_capacity", ("float","1d_map")],
             ["unit", "efficiency", ("float","1d_map","3d_map")],
             ["unit", "efficiency_at_min_load", ("float",)],
             ["unit", "existing", ("float","1d_map")],
             ["unit", "fixed_cost", ("float","1d_map")],
             ["unit", "interest_rate", ("float","1d_map")],
             ["unit", "invest_cost", ("float","1d_map")],
             ["unit", "invest_max_period", ("1d_map",)],
             ["unit", "invest_max_total", ("float",)],
             ["unit", "invest_method", ("str",)],
             ["unit", "invest_min_period", ("1d_map",)],
             ["unit", "invest_min_total", ("float",)],
             ["unit", "lifetime", ("float","1d_map")],
             ["unit", "lifetime_method", ("str",)],
             ["unit", "min_downtime", ("float",)],
             ["unit", "min_load", ("float","1d_map","3d_map")],
             ["unit", "min_uptime", ("float",)],
             ["unit", "minimum_time_method", ("str",)],
             ["unit", "retire_max_period", ("1d_map",)],
             ["unit", "retire_max_total", ("float",)],
             ["unit", "retire_min_period", ("1d_map",)],
             ["unit", "retire_min_total", ("float",)],
             ["unit", "salvage_value", ("float","1d_map")],
             ["unit", "startup_cost", ("float",)],
             ["unit", "startup_method", ("str",)],
             ["unit", "virtual_unitsize", ("float",)],
             ["connection__node", "constraint_flow_coefficient", ("1d_map",)],
             ["connection__profile", "profile_method", ("str",)],
             ["node__profile", "profile_method", ("str",)],
             ["unit__inputNode", "coefficient", ("float",)],
             ["unit__inputNode", "constraint_flow_coefficient", ("1d_map",)],
             ["unit__inputNode", "inertia_constant", ("float",)],
             ["unit__inputNode", "is_non_synchronous", ("str",)],
             ["unit__inputNode", "other_operational_cost", ("float","1d_map","3d_map")],
             ["unit__inputNode", "ramp_cost", ("float",)],
             ["unit__inputNode", "ramp_method", ("str",)],
             ["unit__inputNode", "ramp_speed_down", ("float",)],
             ["unit__inputNode", "ramp_speed_up", ("float",)],
             ["unit__outputNode", "coefficient", ("float",)],
             ["unit__outputNode", "constraint_flow_coefficient", ("1d_map",)],
             ["unit__outputNode", "inertia_constant", ("float",)],
             ["unit__outputNode", "is_non_synchronous", ("str",)],
             ["unit__outputNode", "other_operational_cost", ("float","1d_map","3d_map")],
             ["unit__outputNode", "ramp_cost", ("float",)],
             ["unit__outputNode", "ramp_method", ("str",)],
             ["unit__outputNode", "ramp_speed_down", ("float",)],
             ["unit__outputNode", "ramp_speed_up", ("float",)],
             ["reserve__upDown__group", "increase_reserve_ratio", ("float",)],
             ["reserve__upDown__group", "penalty_reserve", ("float",)],
             ["reserve__upDown__group", "reservation",  ("float","1d_map","3d_map")],
             ["reserve__upDown__group", "reserve_method", ("str",)],
             ["unit__node__profile", "profile_method", ("str",)],
             ["reserve__upDown__connection__node", "increase_reserve_ratio", ("float",)],
             ["reserve__upDown__connection__node", "large_failure_ratio", ("float",)],
             ["reserve__upDown__connection__node", "max_share", ("float",)],
             ["reserve__upDown__connection__node", "reliability", ("float",)],
             ["reserve__upDown__unit__node", "increase_reserve_ratio", ("str",)],
             ["reserve__upDown__unit__node", "large_failure_ratio", ("float",)],
             ["reserve__upDown__unit__node", "max_share", ("float",)],
             ["reserve__upDown__unit__node", "reliability", ("float",)]
             ]
    
    return types
    
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('filename',help= "The filepath of the database to be migrated")
    args = parser.parse_args()
    migrate_database(args.filename)