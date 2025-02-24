# © International Renewable Energy Agency 2018-2022

#The FlexTool is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License
#as published by the Free Software Foundation, either §ersion 3 of the License, or (at your option) any later version.

#The FlexTool is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public License along with the FlexTool.  
#If not, see <https://www.gnu.org/licenses/>.

#Author: Juha Kiviluoma (2017-2022), VTT Technical Research Centre of Finland

param datetime0 := gmtime();
display datetime0;

#########################
# Fundamental sets of the model
set entity 'e - contains both nodes and processes';
set process 'p - Particular activity that transfers, converts or stores commodities' within entity;
set processUnit 'Unit processes' within process;
set node 'n - Any location where a balance needs to be maintained' within entity;
set group 'g - Any group of entities that have a set of common constraints';
set commodity 'c - Stuff that is being processed';
set period_time '(d, t) - Time steps in the time periods of the whole timeline' dimen 2;
set period__time_first within period_time;
set period__time_last within period_time;
set solve_period_timeblockset '(solve, d, tb) - All solve, period, timeblockset combinations in the model instance' dimen 3;
set solve_period '(solve, d) - Time periods in the solves to extract periods that can be found in the full data' := setof {(s, d, tb) in solve_period_timeblockset} (s, d);
set period_solve 'picking up periods from solve_period' := setof {(s,d) in solve_period} (d);
set solve_current 'current solve name' dimen 1;
set period 'd - Time periods in the current solve' := setof {(d, t) in period_time} (d);
set period_first dimen 1 within period;
set period_last dimen 1 within period;
set branch_all dimen 1;
set time_branch_all dimen 1;
set period__branch dimen 2 within {period, period};
set branch := setof{(d,b) in period__branch}(b);
set period__year dimen 2;
set year 'y - Years for discount calculations' := setof{(d, y) in period__year}(y);
set timeline__timestep__duration dimen 3;
set time 't - Time steps in the current timelines' := setof {(tl, t, duration) in timeline__timestep__duration} (t); 
set timeblockset__timeline dimen 2;
set timeline := setof{(tb, tl) in timeblockset__timeline} (tl);
set period__timeline := {d in period, tl in timeline : sum{(s, d, tb) in solve_period_timeblockset : s in solve_current && (tb, tl) in timeblockset__timeline} 1};
set method 'm - Type of process that transfers, converts or stores commodities';
set upDown 'upward and downward directions for some variables';
set ct_method;
set ct_method_constant within ct_method;
set ct_method_regular within ct_method;
set startup_method;
set startup_method_no within startup_method;
set fork_method;
set fork_method_yes within fork_method;
set fork_method_no within fork_method;
set reserve_method;
set ramp_method;
set ramp_limit_method within ramp_method;
set ramp_cost_method within ramp_method;
set profile;
set profile_method;
set debug 'flags to output debugging and test results';
set test_dt 'a shorter set of time steps for printing out test results' dimen 2;
set test_t dimen 1;
set model 'dummy set because has to load a table';

set constraint 'user defined greater than, less than or equality constraints between inputs and outputs';
set sense 'sense of user defined constraints';
set sense_greater_than within sense;
set sense_less_than within sense;
set sense_equal within sense;

set commodityParam;
set commodityPeriodParam within commodityParam;
set commodityTimeParam within commodityParam;
set nodeParam;
set nodeParam_def1 within nodeParam;
set nodePeriodParam;
set nodePeriodParamRequired within nodePeriodParam;
set nodePeriodParamInvest within nodePeriodParam;
set nodeTimeParam within nodeParam;
set nodeTimeParamRequired within nodeParam;
set processParam;
set processParam_def1 within processParam;
set processPeriodParam;
set processTimeParam within processParam;
set processPeriodParamRequired within processPeriodParam;
set processPeriodParamInvest within processPeriodParam;
set processTimeParamRequired within processParam;
set sourceSinkParam;
set sourceSinkTimeParam within sourceSinkParam;
set sourceSinkTimeParamRequired within sourceSinkParam;
set sourceSinkPeriodParam within sourceSinkParam;
set sourceSinkPeriodParamRequired within sourceSinkParam;
set reserveParam;
set reserveParam_def1 within reserveParam;
set reserveTimeParam within reserveParam;
set groupParam;
set groupPeriodParam;
set groupTimeParam within groupParam;

set exclude_entity_outputs;
set def_optional_outputs dimen 2;
set optional_outputs dimen 2;
set optional_yes:= setof{(output,value) in optional_outputs: value == 'yes'}(output);
set def_optional_yes := setof{(output,value) in def_optional_outputs: value == 'yes' && (output,'no') not in optional_outputs}(output);
set enable_optional_outputs := optional_yes union def_optional_yes;

set reserve__upDown__group__method dimen 4;
set reserve__upDown__group := setof {(r, ud, g, m) in reserve__upDown__group__method : m <> 'no_reserve'} (r, ud, g);
set reserve 'r - Categories for the reservation of capacity_existing' := setof {(r, ud, ng, r_m) in reserve__upDown__group__method} (r);
set reserve__upDown__group__reserveParam__time dimen 5 within {reserve, upDown, group, reserveTimeParam, time};

set group__param dimen 2 within {group, groupParam};
set group__param__period dimen 3; # within {group, groupPeriodParam, periodAll};
set group__param__time dimen 3 within {group, groupTimeParam, time};
set node__param__period dimen 3; # within {node, nodePeriodParam, periodAll};
set commodity__param__period dimen 3; # within {commodity, commodityPeriodParam, periodAll};
set commodity__param__time dimen 3; # within {commodity, commodityTimeParam, time};
set process__param__period dimen 3; # within {process, processPeriodParam, periodAll};

set period_group 'picking up periods from group data' := setof {(n, param, d) in group__param__period} (d);
set period_node 'picking up periods from node data' := setof {(n, param, d) in node__param__period} (d);
set period_commodity 'picking up periods from commodity data' := setof {(n, param, d) in commodity__param__period} (d);
set period_process 'picking up periods from process data' := setof {(n, param, d) in process__param__period} (d);

set periodAll 'd - Time periods in data (including those currently in use)' := period_group union period_node union period_commodity union period_process union period_solve union branch;


param p_group {g in group, groupParam} default 0;
param pd_group {g in group, groupPeriodParam, d in periodAll} default 0;
param pt_group {g in group, groupTimeParam, time} default 0;
param p_group__process {g in group, p in process, groupParam};


#Method collections use in the model (abstracted methods)
set method_1var_off within method;
set method_1way_off within method;
set method_1way_LP within method;
set method_1way_MIP within method;
set method_2way_off within method;
set method_1way_1var_on within method;
set method_1way_nvar_on within method;
set method_1way within method;
set method_1way_1var within method;
set method_2way_1var within method;
set method_2way within method;
set method_2way_2var within method;
set method_2way_nvar within method;
set method_1way_on within method;
set method_2way_on within method;
set method_1var within method;
set method_nvar within method;
set method_off within method;
set method_on within method;
set method_LP within method;
set method_MIP within method;
set method_direct within method;
set method_indirect within method;
set method_1var_per_way within method;

set invest_method 'methods available for investments';
set invest_method_not_allowed 'method for denying investments' within invest_method;
set divest_method_not_allowed 'method for denying divestments' within invest_method;
set lifetime_method 'methods available for end of lifetime behavior';
set lifetime_method_default within lifetime_method;
set co2_method 'methods available for co2 price and limits';
set co2_price_method within co2_method;
set co2_max_period_method within co2_method;
set co2_max_total_method within co2_method;
set entity__invest_method 'the investment method applied to an entity' dimen 2 within {entity, invest_method};
set entityDivest := setof {(e, m) in entity__invest_method : m not in divest_method_not_allowed} (e);
set entityInvest := setof {(e, m) in entity__invest_method : m not in invest_method_not_allowed} (e);
set entity__lifetime_method_read dimen 2 within {entity, lifetime_method};
set entity__lifetime_method 'the lifetime method applied to an entity' := 
    {e in entity, m in lifetime_method : (e, m) in entity__lifetime_method_read || (sum{(e, m2) in entity__lifetime_method_read} 1 = 0 && m in lifetime_method_default)};
param investableEntities := sum{e in entityInvest} 1;
set group__invest_method 'the investment method applied to a group' dimen 2 within {group, invest_method};
set group_invest := setof {(g, m) in group__invest_method : m not in invest_method_not_allowed} (g);
set group_divest := setof {(g, m) in group__invest_method : m not in divest_method_not_allowed} (g);
set group__co2_method 'the investment method applied to a group' dimen 2 within {group, co2_method};
set group_co2_price := setof {(g, m) in group__co2_method : m in co2_price_method} (g);
set group_co2_max_period := setof {(g, m) in group__co2_method : m in co2_max_period_method} (g);
set group_co2_max_total := setof {(g, m) in group__co2_method : m in co2_max_total_method} (g);
set nodeBalance 'nodes that maintain a node balance' within node;
set nodeState 'nodes that have a state' within node;
set node_type 'node type';
set node__node_type 'node type of a node' dimen 2 within {node, node_type};
set inflow_method 'method for scaling the inflow';
set inflow_method_default within inflow_method;
set node__inflow_method_read 'method for scaling the inflow applied to a node' within {node, inflow_method};
set node__inflow_method dimen 2 within {node, inflow_method} :=
    {n in node, m in inflow_method : (n, m) in node__inflow_method_read || (sum{(n, m2) in node__inflow_method_read} 1 = 0 && m in inflow_method_default)};
set storage_binding_method 'methods for binding storage state between periods';
set storage_binding_method_default within storage_binding_method;
set node__storage_binding_method_read within {node, storage_binding_method};
set node__storage_binding_method dimen 2 within {node, storage_binding_method} :=
    {n in node, m in storage_binding_method : (n, m) in node__storage_binding_method_read || (sum{(n, m2) in node__storage_binding_method_read} 1 = 0 && m in storage_binding_method_default)};
set storage_start_end_method 'method to fix start and/or end value of storage in a model run';
set node__storage_start_end_method within {node, storage_start_end_method};
set storage_solve_horizon_method 'methods to set reference value or price for the end of horizon storage state';
set node__storage_solve_horizon_method within {node, storage_solve_horizon_method};
set storage_nested_fix_method 'methods to set the storage value for lower level solves';
set node__storage_nested_fix_method within {node, storage_nested_fix_method};
set node__profile__profile_method dimen 3 within {node,profile,profile_method};
set group_node 'member nodes of a particular group' dimen 2 within {group, node};
set group_process 'member processes of a particular group' dimen 2 within {group, process};
set group_process_node 'process__nodes of a particular group' dimen 3 within {group, process, node};
set group_entity := group_process union group_node;
set groupInertia 'node groups with an inertia constraint' within group;
set groupNonSync 'node groups with a non-synchronous constraint' within group;
set groupCapacityMargin 'node groups with a capacity margin' within group;
set groupOutput 'groups that will output aggregated results' within group;
set groupOutput_process 'output groups with process members' :=
    {g in groupOutput : sum{(g, p, n) in group_process_node} 1};
set groupOutput_node 'output groups with node members' :=
    {g in groupOutput : sum{(g, n) in group_node} 1 };
set groupOutputNodeFlows 'groups that will output flow results' within group;
set groupOutputNodeFlows_node 'output flow groups with node members' :=
    {g in groupOutputNodeFlows : sum{(g, n) in group_node} 1 };
set groupOutputAggregateFlows 'groups that aggregate flows' within group;

set group__loss_share_type dimen 2;
set group_loss_share 'group that share the loss of load (upward penalty)' := setof {(g, loss_share_type) in group__loss_share_type} (g);

set process_unit 'processes that are unit' within process;
set process_connection 'processes that are connections' within process;
set process__ct_method_read dimen 2 within {process, ct_method};
set process__ct_method dimen 2 within {process, ct_method} := 
    {p in process, m in ct_method 
	   : (p, m) in process__ct_method_read 
	   || (sum{(p, m2) in process__ct_method_read} 1 = 0 && p in process_connection && m in ct_method_regular)
	   || (sum{(p, m2) in process__ct_method_read} 1 = 0 && p in process_unit && m in ct_method_constant)};
set process__startup_method_read dimen 2 within {process, startup_method} default {p in process, 'no_startup'} ;
set process__startup_method dimen 2 within {process, startup_method}:=
    {p in process, m in startup_method : (p, m) in process__startup_method_read || (sum{(p, m2) in process__startup_method_read} 1 = 0 && m in startup_method_no)};
set process_node_ramp_method dimen 3 within {process, node, ramp_method};
set methods dimen 4; 
set process__profile__profile_method dimen 3 within {process, profile, profile_method};
set process__node__profile__profile_method dimen 4 within {process, node, profile, profile_method};
set process_source dimen 2 within {process, entity};
set process_sink dimen 2 within {process, entity};

set process__sink_nonSync_unit dimen 2 within {process, node};
set process_nonSync_connection dimen 1 within {process};

set process_reserve_upDown_node dimen 4;
set process_node_flow_constraint dimen 3 within {process, node, constraint};
set process_capacity_constraint dimen 2 within {process, constraint};
set node_capacity_constraint dimen 2 within {node, constraint};
set node_state_constraint dimen 2 within {node, constraint};
set constraint__sense dimen 2 within {constraint, sense};
set commodity_node dimen 2 within {commodity, node}; 

set dt dimen 2 within period_time;
param dt_jump {(d, t) in dt};
set dtttdt dimen 6;
set dtt := setof {(d, t, t_previous, previous_within_block, previous_period, previous_within_solve) in dtttdt} (d, t, t_previous);
set period_invest dimen 1 within period;
set d_realize_invest dimen 1 within period;
set period_with_history dimen 1 within periodAll;
param p_period_from_solve{period_with_history};
set time_in_use := setof {(d, t) in dt} (t);
set period_in_use := setof {(d, t) in dt} (d);
set period_first_of_solve dimen 1 within period;

set dt_realize_dispatch_input dimen 2 within period_time;
set dt_realize_dispatch := if 'output_horizon' in enable_optional_outputs then dt else dt_realize_dispatch_input;
set d_realized_period := setof {(d, t) in dt_realize_dispatch} (d);
set realized_period__time_last dimen 2 within period_time;
#dt_complete is the timesteps of the whole rolling_window set, not just single roll. For single_solve it is the same as dt
set dt_complete dimen 2 within period_time;
set complete_time_in_use := setof {(d, t) in dt_complete} (t);
param complete_step_duration{(d, t) in dt_complete};

set dt_fix_storage_timesteps dimen 2 within period_time;
set d_fix_storage_period := setof {(d, t) in dt_fix_storage_timesteps} (d);
set ndt_fix_storage_price dimen 3 within  {node, period_solve, time};
set ndt_fix_storage_quantity dimen 3 within  {node, period_solve, time};
set ndt_fix_storage_usage dimen 3 within  {node, period_solve, time};
set n_fix_storage_quantity := setof{(n,d,t) in ndt_fix_storage_quantity}(n);
set n_fix_storage_price := setof{(n,d,t) in ndt_fix_storage_price}(n);
set n_fix_storage_usage := setof{(n,d,t) in ndt_fix_storage_usage}(n);
set dtt_timeline_matching dimen 3 within {period,time,time};

param p_fix_storage_price {node, period_solve, time};
param p_fix_storage_quantity {node, period_solve, time};
param p_fix_storage_usage {node, period_solve, time};
param p_roll_continue_state {node};

set startTime dimen 1 within time;
set startNext dimen 1 within time;
param startNext_index := sum{t in time, t_startNext in startNext : t <= t_startNext} 1;
set modelParam;

set process__param dimen 2 within {process, processParam};
set process__param__time dimen 3 within {process, processTimeParam, time};
set process__param_t := setof {(p, param, t) in process__param__time} (p, param);
set profile_param dimen 1 within {profile};
set profile_param__time dimen 2 within {profile, time};

set connection__param := {(p, param) in process__param : p in process_connection};
set connection__param__time := { (p, param, t) in process__param__time : (p in process_connection)};
set connection__param_t := setof {(connection, param, t) in connection__param__time} (connection, param);
set process__source__param dimen 3 within {process_source, sourceSinkParam};
set process__source__param__time dimen 4 within {process_source, sourceSinkTimeParam, time};
set process__source__param__period dimen 4 within {process_source, sourceSinkPeriodParam, period};
set process__source__param_t := setof {(p, source, param, t) in process__source__param__time} (p, source, param);
set process__sink__param dimen 3 within {process_sink, sourceSinkParam};
set process__sink__param__time dimen 4 within {process_sink, sourceSinkTimeParam, time};
set process__sink__param_t := setof {(p, sink, param, t) in process__sink__param__time} (p, sink, param);
set process__sink__param__period dimen 4 within {process_sink, sourceSinkPeriodParam, period};

set node__param dimen 2 within {node, nodeParam};
set node__param__time dimen 3 within {node, nodeTimeParam, time};
set node__time_inflow dimen 2 within {node, time};

param p_model {modelParam};
param p_nested_model {modelParam};
param p_commodity {c in commodity, commodityParam} default 0;
param pd_commodity {c in commodity, commodityPeriodParam, d in periodAll} default 0;
param pt_commodity {c in commodity, commodityTimeParam, time} default 0;

param p_node {node, nodeParam} default 0;
param pd_node {node, nodePeriodParam, periodAll} default 0;
param pt_node {node, nodeTimeParam, time} default 0;
param pt_node_inflow {node, time} default 0;

param p_process_source {(p, source) in process_source, sourceSinkParam} default 0;
param pt_process_source {(p, source) in process_source, sourceSinkTimeParam, time} default 0;
param pd_process_source {(p, source) in process_source, sourceSinkPeriodParam, period} default 0;
param p_process_sink {(p, sink) in process_sink, sourceSinkParam} default 0;
param pt_process_sink {(p, sink) in process_sink, sourceSinkTimeParam, time} default 0;
param pd_process_sink {(p, sink) in process_sink, sourceSinkPeriodParam, period} default 0;

param p_process_source_coefficient {(p, source) in process_source} default 1;
param p_process_sink_coefficient {(p, sink) in process_sink} default 1;

param p_profile {profile};
param pt_profile {profile, time};

param reserveParam_defaults{rp in reserveParam}:= (if rp in reserveParam_def1 then 1 else if rp == 'penalty_reserve' then 5000 else 0);
param p_reserve_upDown_group {reserve, upDown, group, rp in reserveParam} default reserveParam_defaults[rp];
param pt_reserve_upDown_group {reserve, upDown, group, reserveTimeParam, time};
param p_process_reserve_upDown_node {p in process, r in reserve, ud in upDown, n in node, rp in reserveParam} default reserveParam_defaults[rp];

param p_process {process, processParam} default 0;
param pd_process {process, processPeriodParam, periodAll} default 0;
param pt_process {process, processTimeParam, time} default 0;

param p_constraint_constant {constraint} default 0;
param p_process_node_constraint_flow_coefficient {process, node, constraint};
param p_process_constraint_capacity_coefficient {process, constraint};
param p_node_constraint_capacity_coefficient {node, constraint};
param p_node_constraint_state_coefficient {node, constraint};
param step_duration{(d, t) in dt};
param p_hole_multiplier {solve_current} default 1;

param p_timeline_duration_in_years{timeline};
param p_years_represented{d in period, y in year} default 1;
param p_years_from_solve{d in period, y in year} default 0;
param p_discount_years{d in period} default 0;
param p_discount_rate{model} default 0.05;
param p_discount_offset_investment{model} default 0;    # Calculate investment annuity assuming they are on average taking place at the middle of the year (unless other value is given)
param p_discount_offset_operations{model} default 0.5;  # Calculate operational costs assuming they are on average taking place at the middle of the year (unless other value is given)

param p_entity_divested {e in entity : e in entityDivest};
set ed_history_realized_read dimen 2 within {e in entity, d in period_with_history};
param p_entity_period_existing_capacity {e in entity, d in period_with_history};
param p_entity_period_invested_capacity {e in entity, d in period_with_history};


####
#Stochastic sets and params
####
set groupStochastic dimen 1 within {group};
set solve_branch__time_branch dimen 2 within {branch_all, time_branch_all};
param p_branch_weight_input {b in branch} default 1;
#normalize the branches with the same starting time to add up to 1
param pd_branch_weight {d in period_in_use} := 
p_branch_weight_input[d] /(sum{(d2,b) in period__branch, (b, ts) in period__time_first: (d,ts) in period__time_first && (d2,d) in period__branch} p_branch_weight_input[b]);

param pdt_branch_weight {(d,t) in dt} := 
p_branch_weight_input[d] /(sum{(d2,b) in period__branch: (b,t) in dt && (d2,d) in period__branch} p_branch_weight_input[b]);

set dt_non_anticipativity := dt_realize_dispatch_input union dt_fix_storage_timesteps;

#stochastic versions of timeseries
set process__param__branch__time dimen 5 within {process, processTimeParam, time_branch_all, time, time};
set profile__branch__time dimen 4 within {profile, time_branch_all, time, time};
set process__source__param__branch__time dimen 6 within {process_source, sourceSinkTimeParam, time_branch_all, time, time};
set process__sink__param__branch__time dimen 6 within {process_sink, sourceSinkTimeParam, time_branch_all, time, time};
set node__param__branch__time dimen 5 within {node, nodeTimeParam, time_branch_all, time, time};
set node__branch__time_inflow dimen 4 within {node, time_branch_all, time, time};
set reserve__upDown__group__reserveParam__branch__time dimen 7 within {reserve, upDown, group, reserveTimeParam, time_branch_all, time, time};

param pbt_node {node, nodeTimeParam, time_branch_all, time, time} default 0;
param pbt_node_inflow {node, time_branch_all, time, time} default 0;
param pbt_process_source {(p, source) in process_source, sourceSinkTimeParam, time_branch_all, time, time} default 0;
param pbt_process_sink {(p, sink) in process_sink, sourceSinkTimeParam, time_branch_all, time, time} default 0;
param pbt_profile {profile, time_branch_all, time, time} default 0;
param pbt_reserve_upDown_group {reserve, upDown, group, reserveTimeParam, time_branch_all, time, time} default 0;
param pbt_process {process, processTimeParam, time_branch_all, time, time} default 0;

param scale_the_objective;
param scale_the_state;

set param_costs dimen 1;
param costs_discounted {param_costs} default 0;

set class_paramName_default dimen 2;
param default_value {class_paramName_default};

#########################
# Read data
#table data IN 'CSV' '.csv' :  <- [];
# Domain sets
table data IN 'CSV' 'input/commodity.csv' : commodity <- [commodity];
table data IN 'CSV' 'input/constraint__sense.csv' : constraint <- [constraint];
table data IN 'CSV' 'input/debug.csv': debug <- [debug];
table data IN 'CSV' 'input/entity.csv': entity <- [entity];
table data IN 'CSV' 'input/group.csv' : group <- [group];
table data IN 'CSV' 'input/node.csv' : node <- [node];
table data IN 'CSV' 'input/nodeBalance.csv' : nodeBalance <- [nodeBalance];
table data IN 'CSV' 'input/nodeState.csv' : nodeState <- [nodeState];
table data IN 'CSV' 'input/node__node_type.csv' : node__node_type <- [node, node_type];
table data IN 'CSV' 'input/groupInertia.csv' : groupInertia <- [groupInertia];
table data IN 'CSV' 'input/groupNonSync.csv' : groupNonSync <- [groupNonSync];
table data IN 'CSV' 'input/groupCapacityMargin.csv' : groupCapacityMargin <- [groupCapacityMargin];
table data IN 'CSV' 'input/groupOutput.csv' : groupOutput <- [groupOutput];
table data IN 'CSV' 'input/groupOutputNodeFlows.csv' : groupOutputNodeFlows <- [groupOutputNodeFlows];
table data IN 'CSV' 'input/groupOutputAggregateFlows.csv' : groupOutputAggregateFlows <- [groupOutputAggregateFlows];
table data IN 'CSV' 'input/process.csv': process <- [process];
table data IN 'CSV' 'input/profile.csv': profile <- [profile];
table data IN 'CSV' 'input/optional_outputs.csv': optional_outputs <- [output, value];
table data IN 'CSV' 'input/exclude_entity_outputs.csv': exclude_entity_outputs <- [value];
table data IN 'CSV' 'input/groupIncludeStochastics.csv' : groupStochastic <- [group];

# Single dimension membership sets
table data IN 'CSV' 'input/process_connection.csv': process_connection <- [process_connection];
table data IN 'CSV' 'input/process_nonSync_connection.csv': process_nonSync_connection <- [process];
table data IN 'CSV' 'input/process_unit.csv': process_unit <- [process_unit];

# Multi dimension membership sets
table data IN 'CSV' 'input/commodity__node.csv' : commodity_node <- [commodity,node];
table data IN 'CSV' 'input/entity__invest_method.csv' : entity__invest_method <- [entity,invest_method];
table data IN 'CSV' 'input/group__invest_method.csv' : group__invest_method <- [group,invest_method];
table data IN 'CSV' 'input/entity__lifetime_method.csv' : entity__lifetime_method_read <- [entity,lifetime_method];
table data IN 'CSV' 'input/group__co2_method.csv' : group__co2_method <- [group,co2_method];
table data IN 'CSV' 'input/group__loss_share_type.csv' : group__loss_share_type <- [group,loss_share_type];
table data IN 'CSV' 'input/node__inflow_method.csv' : node__inflow_method_read <- [node,inflow_method];
table data IN 'CSV' 'input/node__storage_binding_method.csv' : node__storage_binding_method_read <- [node,storage_binding_method];
table data IN 'CSV' 'input/node__storage_start_end_method.csv' : node__storage_start_end_method <- [node,storage_start_end_method];
table data IN 'CSV' 'input/node__storage_solve_horizon_method.csv' : node__storage_solve_horizon_method <- [node,storage_solve_horizon_method];
table data IN 'CSV' 'input/node__storage_nested_fix_method.csv' : node__storage_nested_fix_method <- [node,storage_nested_fix_method];
table data IN 'CSV' 'input/node__profile__profile_method.csv' : node__profile__profile_method <- [node,profile,profile_method];
table data IN 'CSV' 'input/group__node.csv' : group_node <- [group,node];
table data IN 'CSV' 'input/group__process.csv' : group_process <- [group,process];
table data IN 'CSV' 'input/group__process__node.csv' : group_process_node <- [group,process,node];
table data IN 'CSV' 'input/p_process_node_constraint_flow_coefficient.csv' : process_node_flow_constraint <- [process, node, constraint];
table data IN 'CSV' 'input/p_process_constraint_capacity_coefficient.csv' : process_capacity_constraint <- [process, constraint];
table data IN 'CSV' 'input/p_node_constraint_capacity_coefficient.csv' : node_capacity_constraint <- [node, constraint];
table data IN 'CSV' 'input/p_node_constraint_state_coefficient.csv' : node_state_constraint <- [node, constraint];
table data IN 'CSV' 'input/constraint__sense.csv' : constraint__sense <- [constraint, sense];
table data IN 'CSV' 'input/p_process.csv' : process__param <- [process, processParam];
table data IN 'CSV' 'input/p_profile.csv' : profile_param <- [profile];
table data IN 'CSV' 'input/p_node.csv' : node__param <- [node, nodeParam];
table data IN 'CSV' 'input/pd_node.csv' : node__param__period <- [node, nodeParam, period];
table data IN 'CSV' 'input/pd_process.csv' : process__param__period <- [process, processParam, period];
table data IN 'CSV' 'input/p_group.csv' : group__param <- [group, groupParam];
table data IN 'CSV' 'input/pd_group.csv' : group__param__period <- [group, groupParam, period];
table data IN 'CSV' 'input/process__ct_method.csv' : process__ct_method_read <- [process,ct_method];
table data IN 'CSV' 'input/process__node__ramp_method.csv' : process_node_ramp_method <- [process,node,ramp_method];
table data IN 'CSV' 'input/process__reserve__upDown__node.csv' : process_reserve_upDown_node <- [process,reserve,upDown,node];
table data IN 'CSV' 'input/process__sink.csv' : process_sink <- [process,sink];
table data IN 'CSV' 'input/process__source.csv' : process_source <- [process,source];
table data IN 'CSV' 'input/process__sink_nonSync_unit.csv' : process__sink_nonSync_unit <- [process,sink];
table data IN 'CSV' 'input/process__startup_method.csv' : process__startup_method_read <- [process,startup_method];
table data IN 'CSV' 'input/process__profile__profile_method.csv' : process__profile__profile_method <- [process,profile,profile_method];
table data IN 'CSV' 'input/process__node__profile__profile_method.csv' : process__node__profile__profile_method <- [process,node,profile,profile_method];
table data IN 'CSV' 'input/reserve__upDown__group__method.csv' : reserve__upDown__group__method <- [reserve,upDown,group,method];
table data IN 'CSV' 'input/timeblocks_in_use.csv' : solve_period_timeblockset <- [solve,period,timeblocks];
table data IN 'CSV' 'input/timeblocks__timeline.csv' : timeblockset__timeline <- [timeblocks,timeline];
table data IN 'CSV' 'solve_data/solve_current.csv' : solve_current <- [solve];
table data IN 'CSV' 'input/p_process_source.csv' : process__source__param <- [process, source, sourceSinkParam];
table data IN 'CSV' 'input/p_process_sink.csv' : process__sink__param <- [process, sink, sourceSinkParam];
table data IN 'CSV' 'input/pd_commodity.csv' : commodity__param__period <- [commodity, commodityParam, period];
table data IN 'CSV' 'input/timeline.csv' : timeline__timestep__duration <- [timeline,timestep,duration];

# Parameters for model data.
table data IN 'CSV' 'input/p_commodity.csv' : [commodity, commodityParam], p_commodity;
table data IN 'CSV' 'input/pd_commodity.csv' : [commodity, commodityParam, period], pd_commodity;
table data IN 'CSV' 'input/p_group__process.csv' : [group, process, groupParam], p_group__process;
table data IN 'CSV' 'input/p_group.csv' : [group, groupParam], p_group;
table data IN 'CSV' 'input/pd_group.csv' : [group, groupParam, period], pd_group;
table data IN 'CSV' 'input/p_node.csv' : [node, nodeParam], p_node;
table data IN 'CSV' 'input/pd_node.csv' : [node, nodeParam, period], pd_node;
table data IN 'CSV' 'input/p_process_node_constraint_flow_coefficient.csv' : [process, node, constraint], p_process_node_constraint_flow_coefficient;
table data IN 'CSV' 'input/p_process_constraint_capacity_coefficient.csv' : [process, constraint], p_process_constraint_capacity_coefficient;
table data IN 'CSV' 'input/p_node_constraint_capacity_coefficient.csv' : [node, constraint], p_node_constraint_capacity_coefficient;
table data IN 'CSV' 'input/p_node_constraint_state_coefficient.csv' : [node, constraint], p_node_constraint_state_coefficient;
table data IN 'CSV' 'input/p_process__reserve__upDown__node.csv' : [process, reserve, upDown, node, reserveParam], p_process_reserve_upDown_node;
table data IN 'CSV' 'input/p_process_sink.csv' : [process, sink, sourceSinkParam], p_process_sink;
table data IN 'CSV' 'input/p_process_sink_coefficient.csv' : [process, sink], p_process_sink_coefficient;
table data IN 'CSV' 'input/p_process_source.csv' : [process, source, sourceSinkParam], p_process_source;
table data IN 'CSV' 'input/p_process_source_coefficient.csv' : [process, source], p_process_source_coefficient;
table data IN 'CSV' 'input/p_constraint_constant.csv' : [constraint], p_constraint_constant;
table data IN 'CSV' 'input/p_process.csv' : [process, processParam], p_process;
table data IN 'CSV' 'input/pd_process.csv' : [process, processParam, period], pd_process;
table data IN 'CSV' 'input/pd_process_source.csv' : process__source__param__period <- [process, source, sourceSinkPeriodParam, period], pd_process_source~pd_process_source;
table data IN 'CSV' 'input/pd_process_sink.csv' : process__sink__param__period <- [process, sink, sourceSinkPeriodParam, period], pd_process_sink~pd_process_sink;
table data IN 'CSV' 'input/p_profile.csv' : [profile], p_profile;
table data IN 'CSV' 'input/p_reserve__upDown__group.csv' : [reserve, upDown, group, reserveParam], p_reserve_upDown_group;
table data IN 'CSV' 'input/timeline_duration_in_years.csv' : [timeline], p_timeline_duration_in_years;
table data IN 'CSV' 'solve_data/p_discount_years.csv' : [period], p_discount_years~param;
table data IN 'CSV' 'solve_data/p_years_represented.csv' : period__year <- [period,years_from_solve], p_years_represented~p_years_represented, p_years_from_solve~p_years_from_solve;
table data IN 'CSV' 'input/p_discount_rate.csv' : model <- [model];
table data IN 'CSV' 'input/p_discount_rate.csv' : [model], p_discount_rate;
table data IN 'CSV' 'input/default_values.csv' : class_paramName_default <-[class, paramName];
table data IN 'CSV' 'input/default_values.csv' : [class,paramName], default_value;

#Timeseries parameters, Timestep values are in solve_data as they might be averaged for the solve
table data IN 'CSV' 'solve_data/pt_commodity.csv' : commodity__param__time <- [commodity, commodityParam, time], pt_commodity~pt_commodity;
table data IN 'CSV' 'solve_data/pt_group.csv' : group__param__time <- [group, groupParam, time], pt_group~pt_group;
table data IN 'CSV' 'solve_data/pt_node.csv' : node__param__time <- [node, nodeParam, time], pt_node~pt_node;
table data IN 'CSV' 'solve_data/pt_node_inflow.csv' : node__time_inflow <- [node, time], pt_node_inflow~pt_node_inflow;
table data IN 'CSV' 'solve_data/pt_process.csv' : process__param__time <- [process, processParam, time], pt_process~pt_process;
table data IN 'CSV' 'solve_data/pt_profile.csv' : profile_param__time <- [profile, time], pt_profile~pt_profile;
table data IN 'CSV' 'solve_data/pt_reserve__upDown__group.csv' : reserve__upDown__group__reserveParam__time <- [reserve, upDown, group, reserveParam, time], pt_reserve_upDown_group~pt_reserve_upDown_group;
table data IN 'CSV' 'solve_data/pt_process_source.csv' : process__source__param__time <- [process, source, sourceSinkTimeParam, time], pt_process_source~pt_process_source;
table data IN 'CSV' 'solve_data/pt_process_sink.csv' : process__sink__param__time <- [process, sink, sourceSinkTimeParam, time], pt_process_sink~pt_process_sink;

# Parameters from the solve loop
table data IN 'CSV' 'solve_data/solve_hole_multiplier.csv' : [solve], p_hole_multiplier;
table data IN 'CSV' 'solve_data/steps_in_use.csv' : dt <- [period, step], step_duration~step_duration;
table data IN 'CSV' 'solve_data/steps_in_timeline.csv' : period_time <- [period,step];
table data IN 'CSV' 'solve_data/first_timesteps.csv' : period__time_first <- [period,step];
table data IN 'CSV' 'solve_data/last_timesteps.csv' : period__time_last <- [period,step];
table data IN 'CSV' 'solve_data/last_realized_timestep.csv' : realized_period__time_last <- [period,step];
table data IN 'CSV' 'solve_data/step_previous.csv' : dtttdt <- [period, time, previous, previous_within_block, previous_period, previous_within_solve];
table data IN 'CSV' 'solve_data/step_previous.csv' : [period, time], dt_jump~jump;
table data IN 'CSV' 'solve_data/period_with_history.csv' : period_with_history <- [period], p_period_from_solve~param;
table data IN 'CSV' 'solve_data/realized_invest_periods_of_current_solve.csv' : d_realize_invest <- [period];
table data IN 'CSV' 'solve_data/invest_periods_of_current_solve.csv' : period_invest <- [period];
table data IN 'CSV' 'input/p_model.csv' : [modelParam], p_model;
table data IN 'CSV' 'solve_data/p_nested_model.csv' : [modelParam], p_nested_model;
table data IN 'CSV' 'solve_data/realized_dispatch.csv' : dt_realize_dispatch_input <- [period, step];
table data IN 'CSV' 'solve_data/fix_storage_timesteps.csv' : dt_fix_storage_timesteps <- [period, step];
table data IN 'CSV' 'solve_data/fix_storage_price.csv' : ndt_fix_storage_price <- [node, period, step], p_fix_storage_price~p_fix_storage_price;
table data IN 'CSV' 'solve_data/fix_storage_quantity.csv' : ndt_fix_storage_quantity <- [node, period, step], p_fix_storage_quantity~p_fix_storage_quantity;
table data IN 'CSV' 'solve_data/fix_storage_usage.csv' : ndt_fix_storage_usage <- [node, period, step], p_fix_storage_usage~p_fix_storage_usage;
table data IN 'CSV' 'solve_data/timeline_matching_map.csv' : dtt_timeline_matching <- [period, step, upper_step];
table data IN 'CSV' 'solve_data/steps_complete_solve.csv' : dt_complete <- [period, step];
table data IN 'CSV' 'solve_data/steps_complete_solve.csv' : [period, step], complete_step_duration;
table data IN 'CSV' 'solve_data/p_roll_continue_state.csv' : [node], p_roll_continue_state;
table data IN 'CSV' 'solve_data/branch_all.csv' : branch_all <- [branch];
table data IN 'CSV' 'solve_data/time_branch_all.csv' : time_branch_all <- [time_branch];
table data IN 'CSV' 'solve_data/period__branch.csv' : period__branch <- [period, branch];
table data IN 'CSV' 'solve_data/solve_branch_weight.csv' : [branch], p_branch_weight_input;
table data IN 'CSV' 'solve_data/solve_branch__time_branch.csv' : solve_branch__time_branch <- [period, branch];
table data IN 'CSV' 'solve_data/period_first.csv' : period_first <- [period];
table data IN 'CSV' 'solve_data/period_last.csv' : period_last <- [period];
table data IN 'CSV' 'solve_data/period_first_of_solve.csv' : period_first_of_solve <- [period];

# Stochastic input data 
table data IN 'CSV' 'solve_data/pbt_node.csv' : node__param__branch__time <- [node, nodeParam, branch, time_start, time], pbt_node~pbt_node;
table data IN 'CSV' 'solve_data/pbt_node_inflow.csv' : node__branch__time_inflow <- [node, branch, time_start, time], pbt_node_inflow~pbt_node_inflow;
table data IN 'CSV' 'solve_data/pbt_process_sink.csv' : process__sink__param__branch__time <- [process, sink, sourceSinkTimeParam, branch, time_start, time], pbt_process_sink~pbt_process_sink;
table data IN 'CSV' 'solve_data/pbt_process_source.csv' : process__source__param__branch__time <-  [process, source, sourceSinkTimeParam, branch, time_start, time], pbt_process_source~pbt_process_source;
table data IN 'CSV' 'solve_data/pbt_process.csv' : process__param__branch__time <- [process, processParam, branch, time_start, time], pbt_process~pbt_process;
table data IN 'CSV' 'solve_data/pbt_profile.csv' : profile__branch__time <- [profile, branch, time_start, time], pbt_profile~pbt_profile;
table data IN 'CSV' 'solve_data/pbt_reserve__upDown__group.csv' : reserve__upDown__group__reserveParam__branch__time <- [reserve, upDown, group, reserveParam, branch, time_start, time], pbt_reserve_upDown_group~pbt_reserve_upDown_group;

# After rolling forward the investment model
table data IN 'CSV' 'solve_data/p_entity_divested.csv' : [entity], p_entity_divested;
table data IN 'CSV' 'solve_data/p_entity_period_existing_capacity.csv' : ed_history_realized_read <- [entity, period];
table data IN 'CSV' 'solve_data/p_entity_period_existing_capacity.csv' : [entity, period], p_entity_period_existing_capacity;
table data IN 'CSV' 'solve_data/p_entity_period_existing_capacity.csv' : [entity, period], p_entity_period_invested_capacity;

# Reading results from previous solves
table data IN 'CSV' 'output/costs_discounted.csv' : [param_costs], costs_discounted;

#check
set nodeBalancePeriod := {n in node : (n, 'balance_within_period') in node__node_type};

set ed_history_realized_first := {e in entity, d in (d_realize_invest union d_fix_storage_period union d_realized_period) : (d,d) in period__branch && p_model["solveFirst"]};
set ed_history_realized := ed_history_realized_read union ed_history_realized_first;

set process__fork_method_yes dimen 2 within {process, fork_method} := 
    {p in process, m in fork_method 
	  : (sum{(p, source) in process_source} 1 > 1 || sum{(p, sink) in process_sink} 1 > 1) && m in fork_method_yes};
set process__fork_method_no dimen 2 within {process, fork_method} := 
    {p in process, m in fork_method 
	  : (sum{(p, source) in process_source} 1 < 2 && sum{(p, sink) in process_sink} 1 < 2) && m in fork_method_no};
set process__fork_method := process__fork_method_yes union process__fork_method_no;
set process_ct_startup_fork_method := 
    { p in process, m1 in ct_method, m2 in startup_method, m3 in fork_method, m in method
	    : (m1, m2, m3, m) in methods
	    && (p, m1) in process__ct_method
	    && (p, m2) in process__startup_method
		&& (p, m3) in process__fork_method
	};

set process_method := setof {(p, m1, m2, m3, m) in process_ct_startup_fork_method} (p, m);
set process__profileProcess__toSink__profile__profile_method :=
    { p in process, (p2, sink, f, fm) in process__node__profile__profile_method
	    :  p = p2
		&& (p, sink) in process_sink
	    && (sum{(p, m) in process_method : m in method_indirect} 1
		    || sum{(p, source) in process_source} 1 < 1)
	};
set process__profileProcess__toSink := setof {(p, p2, sink, f, m) in process__profileProcess__toSink__profile__profile_method} (p, p2, sink);
set process__source__toProfileProcess__profile__profile_method :=
    { (p, source) in process_source, (p2, source, f, fm) in process__node__profile__profile_method
	    :  p = p2
	    && (sum{(p, m) in process_method : m in method_indirect} 1
		    || sum{(p, sink) in process_sink} 1 < 1)
	};
set process__source__toProfileProcess := setof {(p, source, p2, f, m) in process__source__toProfileProcess__profile__profile_method} (p, source, p2);
set process_profile := setof {(p, source, p2) in process__source__toProfileProcess} (p) union setof {(p, p2, sink) in process__profileProcess__toSink} (p);
set process_source_toProcess := 
    { (p, source) in process_source, p2 in process 
	    :  p = p2 
	    && (p2, source) in process_source 
	    && (    ( sum{(p, m) in process_method : m in method_indirect} 1 )
		     || ( sum{(p, m) in process_method : m in method_direct} 1 && sum{(p, sink) in process_sink} 1 < 1 && not (p, source, p2) in process__source__toProfileProcess )
		   )
	};
set process_process_toSink := 
    { p in process, (p2, sink) in process_sink
	    :  p = p2 
	    && (p, sink) in process_sink 
	    && (    ( sum{(p, m) in process_method : m in method_indirect} 1 )
		     || ( sum{(p, m) in process_method : m in method_direct} 1 && sum{(p, source) in process_source} 1 < 1 && not (p, p2, sink) in process__profileProcess__toSink )
		   )
	};
set process_sink_toProcess := 
    { sink in node, p in process, p2 in process 
	    :  p = p2 
	    && (p, sink) in process_sink 
	    && (p2, sink) in process_sink 
	    && sum{(p, m) in process_method : m in method_2way_nvar} 1
	};
set process_process_toSource := 
    { p in process, (p2, source) in process_source
	    :  p = p2 
	    && (p, source) in process_source
	    && sum{(p, m) in process_method : m in method_2way_nvar} 1
	};
set process_source_toSink := 
    { (p, source) in process_source, sink in node
	    :  (p, sink) in process_sink
        && sum{(p, m) in process_method : m in method_direct} 1
	};
set process_source_toProcess_direct :=
    { (p, source) in process_source, p2 in process
	    :  p = p2
        && sum{(p, m) in process_method : m in method_direct} 1
	};
set process_process_toSink_direct :=
    { p in process, p2 in process, sink in node
	    :  p = p2
		&& (p, sink) in process_sink
        && sum{(p, m) in process_method : m in method_direct} 1
	};
set process_sink_toProcess_direct := 
	{ (p, sink) in process_sink, p2 in process
	    :  p = p2
		&& (p, sink) in process_sink
	    && sum{(p, m) in process_method : m in method_2way_2var} 1
	};
set process_process_toSource_direct := 
	{ p in process, p2 in process, source in node
	    :  p = p2
		&& (p, source) in process_source
	    && sum{(p, m) in process_method : m in method_2way_2var} 1
	};
set process_sink_toSource := 
	{ (p, sink) in process_sink, source in node
	    :  (p, source) in process_source
	    && (p, sink) in process_sink
	    && sum{(p, m) in process_method : m in method_2way_2var} 1
	};
set process__source__sink__profile__profile_method_direct :=
    { (p, source, sink) in process_source_toSink, f in profile, fm in profile_method
	    :  sum{(p, m) in process_method : m in method_direct} 1
		&& ( (p, source, f, fm) in process__node__profile__profile_method
		     || (p, sink, f, fm) in process__node__profile__profile_method
		   )
	};
set process_process_toSink_noConversion :=
    { p in process, (p2, sink) in process_sink
	    :  p = p2 
	    && (p, sink) in process_sink 
	    && sum{(p, m) in process_method : m in method_1way_1var && not sum{(p, source) in process_source} 1} 1
	};
set process_source_toProcess_noConversion :=
    { (p, source) in process_source, p2 in process 
	    :  p = p2 
	    && (p2, source) in process_source 
	    && sum{(p, m) in process_method : m in method_1way_1var && not sum{(p, sink) in process_sink} 1} 1
	};

set process_source_sink := 
    process_source_toSink union    # Direct 1-variable
	process_sink_toSource union    # Direct 1-variable, but the other way
	process_source_toProcess union # First step for indirect (from source to process)
	process_process_toSink union   # Second step for indirect (from process to sink)
	process_sink_toProcess union   # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process_process_toSource union # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process__profileProcess__toSink union   # Add profile based inputs to process
	process__source__toProfileProcess union # Add profile based inputs to process	
	process_process_toSink_noConversion union  # Add other operational cost only units
    process_source_toProcess_noConversion;     # Add other operational cost only units

set process_source_sink_alwaysProcess :=
    process_source_toProcess_direct union  # Direct 1-variable, but showing the process in between
	process_process_toSink_direct union
	process_sink_toProcess_direct union
	process_process_toSource_direct union
	process_source_toProcess union # First step for indirect (from source to process)
	process_process_toSink union   # Second step for indirect (from process to sink)
	process_sink_toProcess union   # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process_process_toSource union # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process__profileProcess__toSink union   # Add profile based inputs to process
	process__source__toProfileProcess union # Add profile based inputs to process	
	process_process_toSink_noConversion union  # Add other operational cost only units
    process_source_toProcess_noConversion;     # Add other operational cost only units

set process_source_sink_noEff :=
	process_source_toProcess union # First step for indirect (from source to process)
	process_process_toSink union   # Second step for indirect (from process to sink)
	process_sink_toProcess union   # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process_process_toSource union # Add the 'wrong' direction in 2-way processes with multiple inputs/outputs
	process__profileProcess__toSink union   # Add profile based inputs to process
	process__source__toProfileProcess union # Add profile based inputs to process	
	process_process_toSink_noConversion union  # Add other operational cost only units
    process_source_toProcess_noConversion;     # Add other operational cost only units
	
set process_source_sink_eff :=
    process_source_toSink union    # Direct 1-variable
	process_sink_toSource;         # Direct 1-variable, but the other way

set process__source__sink__profile__profile_method_connection :=
    { (p, sink, source) in process_source_sink, f in profile, m in profile_method
	    : (p, f, m) in process__profile__profile_method
	};
set process__source__sink__profile__profile_method :=
    process__profileProcess__toSink__profile__profile_method union
	process__source__toProfileProcess__profile__profile_method union
	process__source__sink__profile__profile_method_connection union
	process__source__sink__profile__profile_method_direct
;

set process__source__sinkIsNode := {(p, source, sink) in process_source_sink : (p, sink) in process_sink};

set process_online_linear 'processes with an online status using linear variable' := setof {(p, m) in process_method : m in method_LP} p;
set process_online_integer 'processes with an online status using integer variable' := setof {(p, m) in process_method : m in method_MIP} p;
set process_online := process_online_linear union process_online_integer;
set peedt := {(p, source, sink) in process_source_sink, (d, t) in dt};

param pdCommodity {c in commodity, param in commodityPeriodParam, d in period} := 
        + if (c, param, d) in commodity__param__period
		  then pd_commodity[c, param, d]
		  else if exists{(c, param, db) in commodity__param__period: (db, d) in period__branch} 1
      then sum{(db, d) in period__branch} pd_commodity[c, param, db]
      else p_commodity[c, param];

param pdtCommodity {c in commodity, param in commodityTimeParam, (d, t) in dt} :=
        + if (c, param, t) in commodity__param__time
		     then pt_commodity[c, param, t]
        else if (c, param, d) in commodity__param__period
		     then pd_commodity[c, param, d]
	      else p_commodity[c, param];

param pdGroup {g in group, param in groupPeriodParam, d in period} :=
        + if (g, param, d) in group__param__period
		  then pd_group[g, param, d]
      else if exists{(g, param, db) in group__param__period : (db,d) in period__branch} 1
      then sum{(db, d) in period__branch} pd_group[g, param, db]
		  else if (g, param) in group__param
      then p_group[g, param]
      else if param == 'penalty_inertia' || param == 'penalty_capacity_margin' || param == 'penalty_non_synchronous'
      then 5000
		  else 0;

param pdtGroup {g in group, param in groupTimeParam, (d, t) in dt} :=
        + if (g, param, t) in group__param__time
		     then pt_group[g, param, t]
        else if (g, param, d) in group__param__period
		     then pd_group[g, param, d]
	      else if (g, param) in group__param 
		     then p_group[g, param]
        else 0;

set reserve__upDown__group__method_timeseries := {(r, ud, ng, r_m) in reserve__upDown__group__method 
                                                       : r_m = 'timeseries_only'
													   || r_m = 'timeseries_and_dynamic' 
													   || r_m = 'timeseries_and_large_failure' 
													   || r_m = 'all'};
set reserve__upDown__group__method_dynamic := {(r, ud, ng, r_m) in reserve__upDown__group__method 
                                                       : r_m = 'dynamic_only'
													   || r_m = 'timeseries_and_dynamic' 
													   || r_m = 'dynamic_and_large_failure' 
													   || r_m = 'all'};
set reserve__upDown__group__method_n_1 := {(r, ud, ng, r_m) in reserve__upDown__group__method
                                                       : r_m = 'large_failure_only' 
													   || r_m = 'timeseries_and_large_failure' 
													   || r_m = 'dynamic_and_large_failure' 
													   || r_m = 'all'};

set process__method_indirect := {(p, m) in process_method : m in method_indirect};

set process__sourceIsNode__sink_1way_noSinkOrMoreThan1Source := {(p, source, sink) in process_source_sink 
										   : sum{(p,m) in process_method : m in method_1way} 1
										   && (p, source) in process_source 
										   && ( sum{(p, sink2) in process_sink} 1 = 0 || ( sum{(p, source2) in process_source} 1 >= 2) )};
set process__source__sinkIsNode_not2way1var := {(p, source, sink) in process_source_sink : (p, sink) in process_sink 
	                                       && sum{(p,m) in process_method : m not in method_2way_1var} 1};
set process__source__sinkIsNode_2way1var := {(p, source, sink) in process_source_sink : (p, sink) in process_sink 
	                                       && sum{(p,m) in process_method : m in method_2way_1var} 1};
set process_sinkIsNode_2way1var := setof {(p, source, sink) in process__source__sinkIsNode_2way1var} p;
set process__source__sinkIsNode_2way2var := {(p, source, sink) in process_source_sink : (p, sink) in process_sink 
	                                       && sum{(p,m) in process_method : m in method_2way_2var } 1};

set gdt_maxInstantFlow := {g in group, (d, t) in dt : pdtGroup[g, 'max_instant_flow', d, t]};
set gdt_minInstantFlow := {g in group, (d, t) in dt : pdtGroup[g, 'min_instant_flow', d, t]};
		  
set process__source__timeParam := 
    { (p, source) in process_source, param in sourceSinkTimeParam
	    :  (p, source, param) in process__source__param
	    || (p, source, param) in process__source__param_t
	};

set process__sink__timeParam :=
    { (p, sink) in process_sink, param in sourceSinkTimeParam
	    :  (p, sink, param) in process__sink__param
	    || (p, sink, param) in process__sink__param_t
	};

set process__timeParam :=
    { p in process, param in sourceSinkTimeParam
	   :  ((p, param) in process__param && p in process_connection)
	   || ((p, param) in process__param_t && p in process_connection)
	}; 

set process__source__sink__param :=
    { (p, source, sink) in process_source_sink, param in sourceSinkParam
	    :  (p, source, param) in process__source__param
	    || (p, sink, param) in process__sink__param
	    || ((p, param) in process__param && p in process_connection)
	};
set process__source__sink__param_t :=
    { (p, source, sink) in process_source_sink, param in sourceSinkTimeParam
	    :  (p, source, param) in process__source__param
	    || (p, source, param) in process__source__param_t
	    || (p, sink, param) in process__sink__param
	    || (p, sink, param) in process__sink__param_t
	    || ((p, param) in process__param && p in process_connection)
	    || ((p, param) in process__param_t && p in process_connection)
	};


param setup1 := gmtime() - datetime0;
display setup1;
set process_source_sink_param_t := {(p, source, sink) in process_source_sink_eff, param in processTimeParam : (p, param) in process__param_t};

set process__source__sink__ramp_method :=
    { (p, source, sink) in process_source_sink, m in ramp_method
	    :  (p, source, m) in process_node_ramp_method
		|| (p, sink, m) in process_node_ramp_method
	};

set node__PeriodParam_in_use :=
  { n in node, param in nodePeriodParam:
    param in nodePeriodParamRequired 
    || ((n in entityInvest || n in entityDivest) && param in nodePeriodParamInvest)
  };

set node__TimeParam_in_use :=
  { n in node, param in nodeTimeParam:
    (n in nodeBalance && param in nodeTimeParamRequired) 
	|| (n in nodeBalancePeriod && param in nodeTimeParamRequired) 
    || ((n in nodeState) && (param == 'self_discharge_loss' || param == 'availability')) 
    || ((n, 'use_reference_value') in node__storage_solve_horizon_method && param == 'storage_state_reference_value')
  };

param pdNode {(n, param) in node__PeriodParam_in_use, d in period_with_history} :=
    + if (n, param, d) in node__param__period
		   then pd_node[n, param, d]
      else if exists{(n, param, db) in node__param__period: (db, d) in period__branch} 1
           then sum{(db, d) in period__branch} pd_node[n, param, db]
	  else p_node[n, param];

param pdtNode {(n, param) in node__TimeParam_in_use, (d, t) in dt} :=
      + if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (n, param, tb, ts, t) in node__param__branch__time} 1 
           && exists{(g,n) in group_node: g in groupStochastic} 1
             then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_node[n, param, tb, ts, t]
        else if exists{(p,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (p,d) in period__branch && (n, param, tb, ts, t) in node__param__branch__time} 1
             then sum{(p,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (p,d) in period__branch} pbt_node[n, param, tb, ts, t] 
        else if (n, param, t) in node__param__time
		     then pt_node[n, param, t]
        else if (n, param, d) in node__param__period
		     then pd_node[n, param, d]
		else if (n, param) in node__param 
		     then p_node[n, param]
        else if param in nodeParam_def1
             then 1
        else if ('node',param) in class_paramName_default
            then default_value['node', param]
        else 0;

param ptNode_inflow {n in node, t in time} :=
        + if (n, t) in node__time_inflow
		  then pt_node_inflow[n, t]
		  else p_node[n, 'inflow'];
set nodeSelfDischarge :=  {n in nodeState : exists{(d, t) in dt : pdtNode[n, 'self_discharge_loss', d, t]} 1};

set process__PeriodParam_in_use :=
  { p in process, param in processPeriodParam:
    param in processPeriodParamRequired 
    || ((p in entityInvest || p in entityDivest) && param in processPeriodParamInvest)
    || (p in process_online && param == 'startup_cost')
  };

set process_TimeParam_in_use :=
  { p in process, param in processTimeParam:
    param in processTimeParamRequired ||
    ((p, 'min_load_efficiency') in process__ct_method && ((param == 'min_load') || (param == 'efficiency_at_min_load')))
  };

param pdProcess {(p, param) in process__PeriodParam_in_use, d in period_with_history} :=
     + if (p, param, d) in process__param__period
		  then pd_process[p, param, d]
       else if exists{(p, param, db) in process__param__period: (db, d) in period__branch} 1
            then sum{(db, d) in period__branch} pd_process[p, param, db]
	   else if (p, param) in process__param
		    then p_process[p, param]
	   else 0;
param pdtProcess {(p, param) in process_TimeParam_in_use, (d,t) in dt} :=
      + if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (p, param, tb, ts, t) in process__param__branch__time} 1 
	       && exists{(g,p) in group_process: g in groupStochastic} 1
             then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_process[p, param, tb, ts, t]
        else if exists{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch && (p, param, tb, ts, t) in process__param__branch__time} 1
             then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_process[p, param, tb, ts, t] 
        else if (p, param, d) in process__param__period
		     then pd_process[p, param, d]
		else if (p, param, t) in process__param__time
		     then pt_process[p, param, t]
	    else if (p, param) in process__param
		     then p_process[p, param]
        else if param in processParam_def1
             then 1
	    else 0;
param pdtProfile {p in profile, (d,t) in dt} :=
      + if (exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (p, tb, ts, t) in profile__branch__time} 1 
      && ((exists{(pc, p, m) in process__profile__profile_method, (g, pc) in group_process: g in groupStochastic} 1 ) 
      || (exists{(n, p, m) in node__profile__profile_method, (g,n) in group_node: g in groupStochastic} 1)
      || (exists{(pc, n, p, m) in process__node__profile__profile_method, (g,pc) in group_process: g in groupStochastic} 1)))
      then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_profile[p, tb, ts, t]
      else if exists{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch && (p, tb, ts, t) in profile__branch__time} 1
      then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_profile[p, tb, ts, t] 
      else if (p, t) in profile_param__time
		  then pt_profile[p, t]
		  else if (p) in profile_param
		  then p_profile[p]
		  else 0;

param p_entity_unitsize {e in entity} := 
        + if e in process 
		  then ( if p_process[e, 'virtual_unitsize']
                 then p_process[e, 'virtual_unitsize'] 
		         else if e in process && p_process[e, 'existing']
			          then p_process[e, 'existing']
					  else 1000
			   )			 
          else if e in node 
		  then ( if p_node[e, 'virtual_unitsize'] 
                 then p_node[e, 'virtual_unitsize'] 
		         else if e in node && p_node[e, 'existing']
		              then p_node[e, 'existing']
					  else 1000
			   );

param pdEntity_lifetime {e in entity, d in period_with_history} :=
        + if e in process then pdProcess[e, 'lifetime', d]
		  else if e in node then pdNode[e, 'lifetime', d];

param pProcess_source_sink {(p, source, sink, param) in process__source__sink__param} :=
		+ if (p, source, param) in process__source__param
		  then p_process_source[p, source, param]
		  else if (p, sink, param) in process__sink__param
		  then p_process_sink[p, sink, param]
		  else 0;

set process_source_sourceSinkTimeParam_in_use :=
  {(p, source) in process_source, param in sourceSinkTimeParam:
    param in sourceSinkTimeParamRequired ||
    ((p, 'min_load_efficiency') in process__ct_method && ((param == 'min_load') || (param == 'efficiency_at_min_load')))
  };
set process_sink_sourceSinkTimeParam_in_use :=
  { (p, sink) in process_sink, param in sourceSinkTimeParam:
    param in sourceSinkTimeParamRequired ||
    ((p, 'min_load_efficiency') in process__ct_method && ((param == 'min_load') || (param == 'efficiency_at_min_load')))
  };

set process_source_sourceSinkPeriodParam_in_use :=
  {(p, source) in process_source, param in sourceSinkPeriodParam:
    param in sourceSinkPeriodParamRequired ||
    ((p, 'min_load_efficiency') in process__ct_method && ((param == 'min_load') || (param == 'efficiency_at_min_load')))
  };
set process_sink_sourceSinkPeriodParam_in_use :=
  { (p, sink) in process_sink, param in sourceSinkPeriodParam:
    param in sourceSinkPeriodParamRequired ||
    ((p, 'min_load_efficiency') in process__ct_method && ((param == 'min_load') || (param == 'efficiency_at_min_load')))
  };

param pdtProcess_source {(p, source, param) in process_source_sourceSinkTimeParam_in_use, (d, t) in dt} :=  # : sum{d in period : (d, t) in dt} 1
      + if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (p, source, param, tb, ts, t) in process__source__param__branch__time} 1 
           && exists{(g,p) in group_process: g in groupStochastic} 1
             then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_process_source[p, source, param, tb, ts, t]
        else if exists{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch && (p, source, param, tb, ts, t) in process__source__param__branch__time} 1
             then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_process_source[p, source, param, tb, ts, t] 
        else if (p, source, param, d) in process__source__param__period
		     then pd_process_source[p, source, param, d]
	    else if (p, source, param, t) in process__source__param__time
		     then pt_process_source[p, source, param, t]
	    else if (p, source, param) in process__source__param
		    then p_process_source[p, source, param]
	    else 0;
        
param pdtProcess_sink {(p, sink, param) in process_sink_sourceSinkTimeParam_in_use, (d, t) in dt} :=  #  : sum{d in period : (d, t) in dt} 1
      + if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (p, sink, param, tb, ts, t) in process__sink__param__branch__time} 1 
           && exists{(g,p) in group_process: g in groupStochastic} 1
             then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_process_sink[p, sink, param, tb, ts, t]
        else if exists{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch && (p, sink, param, tb, ts, t) in process__sink__param__branch__time} 1
             then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_process_sink[p, sink, param, tb, ts, t] 
        else if (p, sink, param, d) in process__sink__param__period
		     then pd_process_sink[p, sink, param, d]
		else if (p, sink, param, t) in process__sink__param__time
		     then pt_process_sink[p, sink, param, t]
        else if (p, sink, param) in process__sink__param
		     then p_process_sink[p, sink, param]
		else 0;

param pdtProcess_source_sink {(p, source, sink, param) in process__source__sink__param_t, (d, t) in dt} := #  : sum{d in period : (d, t) in dt} 1
      + if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (p, sink, param, tb, ts, t) in process__sink__param__branch__time} 1
      && exists{(g,p) in group_process: g in groupStochastic} 1
      then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_process_sink[p, sink, param, tb, ts, t]
      else if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (p, source, param, tb, ts, t) in process__source__param__branch__time} 1
      && exists{(g,p) in group_process: g in groupStochastic} 1
      then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_process_source[p, source, param, tb, ts, t]
      else if exists{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch &&(p, sink, param, tb, ts, t) in process__sink__param__branch__time} 1
      then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_process_sink[p, sink, param, tb, ts, t]
      else if exists{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch && (p, source, param, tb, ts, t) in process__source__param__branch__time} 1
      then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_process_source[p, source, param, tb, ts, t] 
      else if (p, sink, param, t) in process__sink__param__time
		  then pt_process_sink[p, sink, param, t]
      else if (p, source, param, t) in process__source__param__time
		  then pt_process_source[p, source, param, t]
		  else if (p, param, t) in connection__param__time
		  then pt_process[p, param, t]
		  else if (p, source, param) in process__source__param
		  then p_process_source[p, source, param]
		  else if (p, sink, param) in process__sink__param
		  then p_process_sink[p, sink, param]
		  else if (p, param) in connection__param
		  then p_process[p, param]
		  else 0;


param pdtReserve_upDown_group {(r, ud, g) in reserve__upDown__group, param in reserveTimeParam, (d,t) in dt} :=
      + if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (r, ud, g, param, tb, ts, t) in reserve__upDown__group__reserveParam__branch__time} 1 && g in groupStochastic
      then sum{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch} pbt_reserve_upDown_group[r, ud, g, param, tb, ts, t]
      else if exists{(pe,tb) in solve_branch__time_branch,  (d,ts) in period__time_first: (pe,d) in period__branch && (r, ud, g, param, tb, ts, t) in reserve__upDown__group__reserveParam__branch__time} 1
      then sum{(pe,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (pe,d) in period__branch} pbt_reserve_upDown_group[r, ud, g, param, tb, ts, t] 
      else if (r, ud, g, param, t) in reserve__upDown__group__reserveParam__time
		  then pt_reserve_upDown_group[r, ud, g, param, t]
		  else p_reserve_upDown_group[r, ud, g, param];
set process_reserve_upDown_node_active := {(p, r, ud, n) in process_reserve_upDown_node : sum{(r, ud, g) in reserve__upDown__group} 1};
set prundt := {(p, r, ud, n) in process_reserve_upDown_node_active, (d, t) in dt};
set pdt_online_linear := {p in process_online_linear, (d, t) in dt : pdProcess[p, 'startup_cost', d]};
set pdt_online_integer := {p in process_online_integer, (d, t) in dt : pdProcess[p, 'startup_cost', d]};

param hours_in_period{d in period} := sum {(d, t) in dt} (step_duration[d, t]);
param hours_in_solve := sum {(d, t) in dt} (step_duration[d, t]);
param period_share_of_year{d in period} := hours_in_period[d] / 8760;
param solve_share_of_year := hours_in_solve / 8760;
param p_years_d{d in period_with_history} := p_period_from_solve[d];
#param p_years_d{d in periodAll} := sum {y in year : (d, y) in period__year} p_years_represented[d, y];

param complete_hours_in_period{d in period} := sum {(d2, t) in dt_complete: (d2, d) in period__branch} (complete_step_duration[d2, t]);
param complete_period_share_of_year{d in period} := complete_hours_in_period[d] / 8760;

param period_share_of_annual_flow {n in node, d in period : ((n, 'scale_to_annual_flow') in node__inflow_method || (n, 'scale_to_annual_and_peak_flow') in node__inflow_method)
        && pdNode[n, 'annual_flow', d]} := abs(sum{(d, t) in dt_complete} (ptNode_inflow[n, t])) / pdNode[n, 'annual_flow', d];
param period_flow_annual_multiplier {n in node, d in period : ((n, 'scale_to_annual_flow') in node__inflow_method)
        && pdNode[n, 'annual_flow', d]} := complete_period_share_of_year[d] / period_share_of_annual_flow[n, d];
param orig_flow_sum {n in node, d in period : ((n, 'scale_to_annual_flow') in node__inflow_method || (n, 'scale_to_annual_and_peak_flow') in node__inflow_method)
        && pdNode[n, 'annual_flow', d]}  := sum{t in complete_time_in_use} ptNode_inflow[n, t];
param period_flow_proportional_multiplier {n in node, d in period : (n, 'scale_in_proportion') in node__inflow_method && pdNode[n, 'annual_flow', d]} :=
        pdNode[n, 'annual_flow', d] / (abs(sum{t in time} (ptNode_inflow[n, t])) / sum{(d, tl) in period__timeline} p_timeline_duration_in_years[tl]);
param new_peak_sign{n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        (if pdNode[n, 'peak_inflow', d] >= 0 then 1 else -1);
param old_peak_max{n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        if (n, 'inflow') in node__time_inflow
		then max{t in time} ptNode_inflow[n, t]
		else p_node[n, 'inflow'];
param old_peak_min{n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        if (n, 'inflow') in node__time_inflow
		then min{t in time} ptNode_inflow[n, t]
		else p_node[n, 'inflow'];
param old_peak_sign{n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} :=
		( if (n, 'inflow') in node__time_inflow
		  then (if abs(old_peak_max[n, d]) >= abs(old_peak_min[n, d]) then 1 else -1)
		  else (if p_node[n, 'inflow'] >= 0 then 1 else -1)
		);
param old_peak{n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} :=
        (if old_peak_sign[n, d] >= 0 then old_peak_max[n, d] else old_peak_min[n, d]);
printf ('Checking if the sign of new peak inflow is the same as the sign ');
printf ('of the peak inflow in the original inflow time series\n');
check {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} new_peak_sign[n, d] = old_peak_sign[n, d];

param new_peak_divided_by_old_peak {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        pdNode[n, 'peak_inflow', d] / old_peak[n, d];
param new_peak_divide_by_old_peak_sum_inflow {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        new_peak_divided_by_old_peak[n, d] * orig_flow_sum[n, d] / complete_period_share_of_year[d];
param new_peak_inflow_sum {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        pdNode[n, 'peak_inflow', d] * 8760;
param new_old_multiplier {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} := 
        old_peak_sign[n, d] *
		( old_peak_sign[n, d] * new_peak_divide_by_old_peak_sum_inflow[n, d] - pdNode[n, 'annual_flow', d] 
		)
		/ ( new_peak_inflow_sum[n, d] - new_peak_divide_by_old_peak_sum_inflow[n, d] );
param new_old_slope {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} :=
        new_peak_divided_by_old_peak[n, d] * ( 1 + new_old_multiplier[n, d] );
param new_old_section {n in node, d in period : (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d]} :=
        pdNode[n, 'peak_inflow', d] * new_old_multiplier[n, d];
param pdtNodeInflow {n in node, (d, t) in dt : (n, 'no_inflow') not in node__inflow_method}  := 
        + (if exists{(d,ts) in period__time_first, (d,tb) in solve_branch__time_branch: (n, tb, ts, t) in node__branch__time_inflow} 1 
              && exists{(g,n) in group_node: g in groupStochastic} 1
           then sum{(d,ts) in period__time_first,(d,tb) in solve_branch__time_branch} pbt_node_inflow[n, tb, ts, t]
           else 
		       if exists{(p,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (p,d) in period__branch && (n, tb, ts, t) in node__branch__time_inflow} 1
               then 
			       sum{(p,tb) in solve_branch__time_branch, (d,ts) in period__time_first: (p,d) in period__branch} pbt_node_inflow[n, tb, ts, t]  
               else 
				   + (if n in nodeBalancePeriod
		               then + pdNode[n, 'annual_flow', d] * period_share_of_year[d] / hours_in_period[d])
			       + (if n in nodeBalance && (n, 'scale_to_annual_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] 
				       then + period_flow_annual_multiplier[n, d] * ptNode_inflow[n, t])
			       + (if n in nodeBalance && (n, 'scale_in_proportion') in node__inflow_method && pdNode[n, 'annual_flow', d] 
					   then + period_flow_proportional_multiplier[n, d] * ptNode_inflow[n, t])
				   + (if n in nodeBalance && (n, 'scale_to_annual_and_peak_flow') in node__inflow_method && pdNode[n, 'annual_flow', d] && pdNode[n, 'peak_inflow', d] 
					   then + new_old_slope[n, d] * ptNode_inflow[n, t]
			                - new_old_section[n, d])
				   + (if n in nodeBalance && (n, 'use_original') in node__inflow_method
		               then + ptNode_inflow[n, t])
		  );

param node_capacity_for_scaling{n in node, d in period} := ( if   sum{(p,source,n) in process_source_sink} p_entity_unitsize[p] + sum{(p, n, sink) in process_source_sink} p_entity_unitsize[p]
                                                             then sum{(p,source,n) in process_source_sink} p_entity_unitsize[p] + sum{(p, n, sink) in process_source_sink} p_entity_unitsize[p]
															 else 1000 ); 
param group_capacity_for_scaling{g in group, d in period} := ( if   sum{(g, n) in group_node} node_capacity_for_scaling[n, d]
                                                               then sum{(g, n) in group_node} node_capacity_for_scaling[n, d]
															   else 1000 );

set period__period_next := {d in period, dNext in period : 1 + sum{d2 in period : d2 <=d} 1 = sum{dNext2 in period : dNext2 <=dNext} 1};
param p_disc_rate := (if sum{m in model} 1 then max{m in model} p_discount_rate[m] else 0.05);
param p_disc_offset_investment := (if sum{m in model} 1 then max{m in model} p_discount_offset_investment[m] else 0);
param p_disc_offset_operations := (if sum{m in model} 1 then max{m in model} p_discount_offset_operations[m] else 0.5);
param p_discount_factor_investment{d in period} := 1/(1 + p_disc_rate) ^ (p_discount_years[d] + p_disc_offset_investment);
param p_discount_factor_operations{d in period} := 1/(1 + p_disc_rate) ^ (p_discount_years[d] + p_disc_offset_operations);
param p_discount_factor_investment_yearly{d in period} := 
		if sum{y in year} p_years_represented[d, y]
		then sum{(d, y) in period__year} ( ( 1/(1 + p_disc_rate) ^ (p_discount_years[d] + p_disc_offset_investment) ) * p_years_represented[d, y] )
		else 1;
param p_discount_factor_operations_yearly{d in period} := 
		if sum{y in year} p_years_represented[d, y]
		then sum{(d, y) in period__year} ( ( 1/(1 + p_disc_rate) ^ (p_years_from_solve[d, y] + p_disc_offset_operations) ) * p_years_represented[d, y] )
		else 1;

# Check for division by zero
printf 'Checking: node lifetime parameter > 0, if the node is using investments';
check {e in entityInvest, d in period_invest : e in node} pdNode[e, 'lifetime', d] > 0 ;
printf 'Checking: process (unit and connection) lifetime parameter > 0, if the process is using investments';
check {e in entityInvest, d in period_invest : e in process} pdProcess[e, 'lifetime', d] > 0 ;

param ed_entity_annual{e in entityInvest, d in period_invest} :=
        + sum{m in invest_method : (e, m) in entity__invest_method && e in node && m not in invest_method_not_allowed}
          ( + ( pdNode[e, 'invest_cost', d] * 1000 
		        * ( pdNode[e, 'interest_rate', d] 
			        / (1 - (1 / (1 + pdNode[e, 'interest_rate', d])^pdNode[e, 'lifetime', d] ) ) 
				  )
		       )
			+ pdNode[e, 'fixed_cost', d] * 1000
		  )
        + sum{m in invest_method : (e, m) in entity__invest_method && e in process && m not in invest_method_not_allowed}
		  (
            + (pdProcess[e, 'invest_cost', d] * 1000 * ( pdProcess[e, 'interest_rate', d] 
			  / (1 - (1 / (1 + pdProcess[e, 'interest_rate', d])^pdProcess[e, 'lifetime', d] ) ) ))
			+ pdProcess[e, 'fixed_cost', d] * 1000
		  )
;

param ed_entity_annual_discounted{e in entityInvest, d in period_invest} :=
        + sum{(e,m) in entity__lifetime_method : m = 'reinvest_choice'}
          ( + ed_entity_annual[e, d] 
			    * sum{d_all in period 
				    :    p_discount_years[d_all] >= p_discount_years[d] 
					  && p_discount_years[d_all] < p_discount_years[d] + pdEntity_lifetime[e, d]
				  }
				    ( p_discount_factor_investment_yearly[d_all] )
		  )
        + sum{(e,m) in entity__lifetime_method : m = 'reinvest_automatic'}
		  (
            + ed_entity_annual[e, d] 
			    * sum{d_all in period 
				    :    p_discount_years[d_all] >= p_discount_years[d] 
				  }
				    ( p_discount_factor_investment_yearly[d_all] )
		  )
;
param ed_entity_annual_divest{e in entityDivest, d in period_invest} :=
        + sum{m in invest_method : (e, m) in entity__invest_method && e in node && m not in divest_method_not_allowed}
          ( + (pdNode[e, 'salvage_value', d] * 1000 * ( pdNode[e, 'interest_rate', d] 
			  / (1 - (1 / (1 + pdNode[e, 'interest_rate', d])^pdNode[e, 'lifetime', d] ) ) ))
			+ pdNode[e, 'fixed_cost', d] * 1000
		  )
        + sum{m in invest_method : (e, m) in entity__invest_method && e in process && m not in divest_method_not_allowed}
		  (
            + (pdProcess[e, 'salvage_value', d] * 1000 * ( pdProcess[e, 'interest_rate', d] 
			  / (1 - (1 / (1 + pdProcess[e, 'interest_rate', d])^pdProcess[e, 'lifetime', d] ) ) ))
			+ pdProcess[e, 'fixed_cost', d] * 1000
		  )
; 			
param ed_entity_annual_divest_discounted{e in entityDivest, d in period_invest} :=
        if (e in node) then 
          ( + ed_entity_annual_divest[e, d] 
			    * sum{d_all in period 
				   :    p_discount_years[d_all] >= p_discount_years[d] 
				     && p_discount_years[d_all] < p_discount_years[d] + pdNode[e, 'lifetime', d]
				  }
				    ( p_discount_factor_investment_yearly[d_all] )
		  )
		else if (e in process) then
		  (
            + ed_entity_annual_divest[e, d] 
			    * sum{d_all in period 
				    :    p_discount_years[d_all] >= p_discount_years[d] 
					  && p_discount_years[d_all] < p_discount_years[d] + pdProcess[e, 'lifetime', d]
				  }
				    ( p_discount_factor_investment_yearly[d_all] )
		  )
;

set process_minload := {p in process : (p, 'min_load_efficiency') in process__ct_method};
param pdtProcess_section{p in process_minload, (d, t) in dt} := 
        + 1 / pdtProcess[p, 'efficiency', d, t] 
    	- ( 1 / pdtProcess[p, 'efficiency', d, t] - pdtProcess[p, 'min_load', d, t] / pdtProcess[p, 'efficiency_at_min_load', d, t] ) 
			    / (1 - pdtProcess[p, 'min_load', d, t])
		; 
param pdtProcess_slope{p in process, (d, t) in dt} := 
        1 / pdtProcess[p, 'efficiency', d, t] 
		- (if p in process_minload then pdtProcess_section[p, d, t] else 0);

#         	          * (if (p, 'min_load_efficiency') in process__ct_method then ptProcess_slope[p, t] else 1 / ptProcess[p, 'efficiency', t])
#		              * (if p in process_unit then p_process_sink_coefficient[p, sink] / p_process_source_coefficient[p, n] else 1)

param w_calc_slope := gmtime() - datetime0 - setup1;
display w_calc_slope;

param pdtProcess__source__sink__dt_varCost {(p, source, sink) in process_source_sink, (d, t) in dt} :=
  + (if (p, source) in process_source then pdtProcess_source[p, source, 'other_operational_cost', d, t])
  + (if (p, sink) in process_sink then pdtProcess_sink[p, sink, 'other_operational_cost', d, t])
  + (if (p, source, sink) in process_source_sink then 
      ( if pdtProcess[p, 'other_operational_cost', d, t] then pdtProcess[p, 'other_operational_cost', d, t]
	  )
	)
;

param pdtProcess__source__sink__dt_varCost_alwaysProcess {(p, source, sink) in process_source_sink_alwaysProcess, (d, t) in dt} :=
  + (if (p, source) in process_source then pdtProcess_source[p, source, 'other_operational_cost', d, t])
  + (if (p, sink) in process_sink then pdtProcess_sink[p, sink, 'other_operational_cost', d, t])
  + (if (p, source, sink) in process_source_sink_alwaysProcess 
        && ((p, sink) in process_sink || (p, sink) in process_source)
	 then ( if pdtProcess[p, 'other_operational_cost', d, t] then pdtProcess[p, 'other_operational_cost', d, t]
	      )
    )
;

set pssdt_varCost_noEff := {(p, source, sink) in process_source_sink_noEff, (d, t) in dt : pdtProcess__source__sink__dt_varCost[p, source, sink, d, t]};
set pssdt_varCost_eff_unit_source := {(p, source, sink) in process_source_sink_eff, (d, t) in dt : (p, source) in process_source && pdtProcess_source[p, source, 'other_operational_cost', d, t]};
set pssdt_varCost_eff_unit_sink := {(p, source, sink) in process_source_sink_eff, (d, t) in dt : (p, sink) in process_sink && pdtProcess_sink[p, sink, 'other_operational_cost', d, t]};
set pssdt_varCost_eff_connection := {(p, source, sink) in process_source_sink_eff, (d, t) in dt : pdtProcess[p,'other_operational_cost', d, t]};
set ed_invest := {e in entityInvest, d in period_invest : ed_entity_annual[e, d] || sum{(e, c) in process_capacity_constraint} 1 || sum{(e, c) in node_capacity_constraint} 1 };
set ed_invest_period := {(e, d) in ed_invest : (e, 'invest_period') in entity__invest_method || (e, 'invest_period_total') in entity__invest_method 
                                               || (e, 'invest_retire_period') in entity__invest_method || (e, 'invest_retire_period_total') in entity__invest_method};
set e_invest_total := {e in entityInvest : (e, 'invest_total') in entity__invest_method || (e, 'invest_period_total') in entity__invest_method 
                                               || (e, 'invest_retire_total') in entity__invest_method || (e, 'invest_retire_period_total') in entity__invest_method};
set ed_invest_cumulative := {(e, d) in ed_invest : (e, 'cumulative_limits') in entity__invest_method}; 
set edd_history_choice := {e in entity, d_history in period_with_history, d in period : (e, 'reinvest_choice') in entity__lifetime_method && p_years_d[d] >= p_years_d[d_history] && p_years_d[d] < p_years_d[d_history] + pdEntity_lifetime[e, d_history]};
set edd_history_automatic := {e in entity, d_history in period_with_history, d in period : (e, 'reinvest_automatic') in entity__lifetime_method && p_years_d[d] >= p_years_d[d_history]};
set edd_history := edd_history_choice union edd_history_automatic;
set edd_history_invest := {(e, d_invest, d) in edd_history : e in entityInvest};
set edd_invest := {(e, d_invest, d) in edd_history_invest : d_invest in period_invest};
set pd_invest := {(p, d) in ed_invest : p in process};
set nd_invest := {(n, d) in ed_invest : n in node};
set ed_divest := {e in entityDivest, d in period_invest : ed_entity_annual_divest[e, d] || sum{(e, c) in process_capacity_constraint} 1 || sum{(e, c) in node_capacity_constraint} 1 };
set ed_divest_period := {(e, d) in ed_invest : (e, 'retire_period') in entity__invest_method || (e, 'retire_period_total') in entity__invest_method 
                                               || (e, 'invest_retire_period') in entity__invest_method || (e, 'invest_retire_period_total') in entity__invest_method};
set e_divest_total := {e in entityDivest : (e, 'retire_total') in entity__invest_method || (e, 'retire_period_total') in entity__invest_method 
                                               || (e, 'invest_retire_total') in entity__invest_method || (e, 'invest_retire_period_total') in entity__invest_method};
set pd_divest := {(p, d) in ed_divest : p in process};
set nd_divest := {(n, d) in ed_divest : n in node};

set gd_invest := {g in group_invest, d in period_invest : sum{(g, e) in group_entity : (e, d) in ed_invest} 1};
set gd_invest_period := {(g, d) in gd_invest : (g, 'invest_period') in group__invest_method || (g, 'invest_period_total') in group__invest_method 
                                               || (g, 'invest_retire_period') in group__invest_method || (g, 'invest_retire_period_total') in group__invest_method};
set g_invest_total := {g in group_invest : (g, 'invest_total') in group__invest_method || (g, 'invest_period_total') in group__invest_method 
                                               || (g, 'invest_retire_total') in group__invest_method || (g, 'invest_retire_period_total') in group__invest_method};
set gd_divest := {g in group_invest, d in period_invest : sum{(g, e) in group_entity : (e, d) in ed_invest} 1};
set gd_divest_period := {(g, d) in gd_invest : (g, 'retire_period') in group__invest_method || (g, 'retire_period_total') in group__invest_method 
                                               || (g, 'invest_retire_period') in group__invest_method || (g, 'invest_retire_period_total') in group__invest_method};
set g_divest_total := {g in group_divest : (g, 'retire_total') in group__invest_method || (g, 'retire_period_total') in group__invest_method 
                                               || (g, 'invest_retire_total') in group__invest_method || (g, 'invest_retire_period_total') in group__invest_method};

param e_invest_max_total{e in entityInvest} :=
  + (if e in process then p_process[e, 'invest_max_total'])
  + (if e in node then p_node[e, 'invest_max_total'])
;  

param e_divest_max_total{e in entityDivest} :=
  + (if e in process then p_process[e, 'retire_max_total'])
  + (if e in node then p_node[e, 'retire_max_total'])
;  

param e_invest_min_total{e in entityInvest} :=
  + (if e in process then p_process[e, 'invest_min_total'])
  + (if e in node then p_node[e, 'invest_min_total'])
;  

param e_divest_min_total{e in entityDivest} :=
  + (if e in process then p_process[e, 'retire_min_total'])
  + (if e in node then p_node[e, 'retire_min_total'])
;  

param ed_invest_max_period{(e, d) in ed_invest} :=
  + (if e in process then pdProcess[e, 'invest_max_period', d])
  + (if e in node then pdNode[e, 'invest_max_period', d])
;  

param ed_divest_max_period{(e, d) in ed_divest} :=
  + (if e in process then pdProcess[e, 'retire_max_period', d])
  + (if e in node then pdNode[e, 'retire_max_period', d])
;  

param ed_invest_min_period{(e, d) in ed_invest} :=
  + (if e in process then pdProcess[e, 'invest_min_period', d])
  + (if e in node then pdNode[e, 'invest_min_period', d])
;  

param ed_divest_min_period{(e, d) in ed_divest} :=
  + (if e in process then pdProcess[e, 'retire_min_period', d])
  + (if e in node then pdNode[e, 'retire_min_period', d])
;  

param ed_cumulative_max_capacity{(e, d) in ed_invest} :=
  + (if e in process then pdProcess[e, 'cumulative_max_capacity', d])
  + (if e in node then pdNode[e, 'cumulative_max_capacity', d])
;  

param ed_cumulative_min_capacity{(e, d) in ed_invest} :=
  + (if e in process then pdProcess[e, 'cumulative_min_capacity', d])
  + (if e in node then pdNode[e, 'cumulative_min_capacity', d])
;  

set process_source_sink_ramp_limit_source_up :=
    {(p, source, sink) in process_source_sink
	    : ( sum{(p, source, m) in process_node_ramp_method : m in ramp_limit_method} 1
		    && p_process_source[p, source, 'ramp_speed_up'] > 0
		  )
	};
set process_source_sink_ramp_limit_sink_up :=
    {(p, source, sink) in process_source_sink
	    : ( sum{(p, sink, m) in process_node_ramp_method : m in ramp_limit_method} 1
		    && p_process_sink[p, sink, 'ramp_speed_up'] > 0
		  )
	};
set process_source_sink_ramp_limit_source_down :=
    {(p, source, sink) in process_source_sink
	    : ( sum{(p, source, m) in process_node_ramp_method : m in ramp_limit_method} 1
		    && p_process_source[p, source, 'ramp_speed_down'] > 0
		  )
	};
set process_source_sink_ramp_limit_sink_down :=
    {(p, source, sink) in process_source_sink
	    : ( sum{(p, sink, m) in process_node_ramp_method : m in ramp_limit_method} 1
		    && p_process_sink[p, sink, 'ramp_speed_down'] > 0
		  )
	};
set process_source_sink_ramp_cost :=
    {(p, source, sink) in process_source_sink
	    : sum{(p, source, m) in process_node_ramp_method : m in ramp_cost_method} 1
		  || sum{(p, sink, m) in process_node_ramp_method : m in ramp_cost_method} 1
	};
set process_source_sink_ramp :=
    process_source_sink_ramp_limit_source_up 
    union process_source_sink_ramp_limit_sink_up 
	union process_source_sink_ramp_limit_source_down 
	union process_source_sink_ramp_limit_sink_down 
	union process_source_sink_ramp_cost;

set process_source_sink_dtttdt_ramp_limit_source_up :=
        {(p, source, sink) in process_source_sink_ramp_limit_source_up, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt :
 		    p_process_source[p, source, 'ramp_speed_up'] * 60 < step_duration[d, t] && dt_jump[d, t] == 1
        };
set process_source_sink_dtttdt_ramp_limit_sink_up :=
        {(p, source, sink) in process_source_sink_ramp_limit_sink_up, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt :
 		    p_process_sink[p, sink, 'ramp_speed_up'] * 60 < step_duration[d, t] && dt_jump[d, t] == 1
        };
set process_source_sink_dtttdt_ramp_limit_source_down :=
        {(p, source, sink) in process_source_sink_ramp_limit_source_down, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt :
 		    p_process_source[p, source, 'ramp_speed_down'] * 60 < step_duration[d, t] && dt_jump[d, t] == 1
        };
set process_source_sink_dtttdt_ramp_limit_sink_down :=
        {(p, source, sink) in process_source_sink_ramp_limit_sink_down, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt :
 		    p_process_sink[p, sink, 'ramp_speed_down'] * 60 < step_duration[d, t] && dt_jump[d, t] == 1
        };

set process_reserve_upDown_node_increase_reserve_ratio :=
        {(p, r, ud, n) in process_reserve_upDown_node_active :
		    p_process_reserve_upDown_node[p, r, ud, n, 'increase_reserve_ratio'] > 0
		};
set process_reserve_upDown_node_large_failure_ratio :=
        {(p, r, ud, n) in process_reserve_upDown_node_active :
		    p_process_reserve_upDown_node[p, r, ud, n, 'large_failure_ratio'] > 0
		};
set process_large_failure := setof {(p, r, ud, n) in process_reserve_upDown_node_large_failure_ratio} p;
 
set gcndt_co2_price := 
        {g in group, (c,n) in commodity_node, d in period, t in time_in_use: (d,t) in dt 
        && (g, n) in group_node 
        && p_commodity[c, 'co2_content']
        && g in group_co2_price
        && pdtGroup[g, 'co2_price', d, t]
      };

set group_commodity_node_period_co2_period :=
        {g in group, (c, n) in commodity_node, d in period : 
		    (g, n) in group_node 
			&& p_commodity[c, 'co2_content'] 
			&& g in group_co2_max_period
		};

set group_commodity_node_period_co2_total :=
        {g in group, (c, n) in commodity_node : 
		    (g, n) in group_node 
			&& p_commodity[c, 'co2_content'] 
			&& g in group_co2_max_total
		};


set process__commodity__node := {p in process, (c, n) in commodity_node : (p, n) in process_source || (p, n) in process_sink};

set commodity_node_co2 :=
        {(c, n) in commodity_node : 
			p_commodity[c, 'co2_content'] 
		};

set process__commodity__node_co2 := {p in process, (c, n) in commodity_node_co2 : (p, n) in process_source || (p, n) in process_sink};
set process_co2 := setof{(p, c, n) in process__commodity__node_co2} p;

set process__sink_nonSync :=
        {p in process, sink in node :
		       ( (p, sink) in process_sink && (p, sink) in process__sink_nonSync_unit )
			|| ( (p, sink) in process_sink && p in process_nonSync_connection )
			|| ( (p, sink) in process_source && p in process_nonSync_connection )  
	    };

set process__group_inside_group_nonSync :=
  {p in process, g in groupNonSync:
  sum{source in node, sink in node: 
  (p,source) in process_source && (g, source) in group_node 
  && (p,sink) in process_sink && (g,sink) in group_node  
  && source != sink } 1
  }; 
  #|| sum{(p,m) in process_method: m in method_2way_1var} 1

set group_output__process_fully_inside :=
  {g in groupOutputNodeFlows, p in process
     : sum {(p, source) in process_source : (g, source) in group_node} 1   # source node is in the group
       && sum {(p, sink) in process_sink : (g, sink) in group_node} 1      # sink node is in the group
	   && not sum {(p, source, sink) in process_source_sink : source == sink} 1  # but source and sink can't be the same (rule out e.g. battery storage)
  }; 
set group_output__process__unit__to_node_not_in_aggregate :=
    {g in groupOutputNodeFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_unit 
								 && (g, sink) in group_node 
								 && (g, p) not in group_output__process_fully_inside
								 && not sum{(ga, p, sink) in group_process_node : ga in groupOutputAggregateFlows} 1};
set group_output__process__node__to_unit_not_in_aggregate :=
    {g in groupOutputNodeFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_unit 
								 && (g, source) in group_node 
								 && (g, p) not in group_output__process_fully_inside
								 && not sum{(ga, p, source) in group_process_node : ga in groupOutputAggregateFlows} 1};
set group_output__group_aggregate__process__unit__to_node :=
    {g in groupOutputNodeFlows, ga in groupOutputAggregateFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_unit 
								 && (g, sink) in group_node 
								 && (ga, p, sink) in group_process_node
								 && (g, p) not in group_output__process_fully_inside};
set group_output__group_aggregate__process__node__to_unit :=
    {g in groupOutputNodeFlows, ga in groupOutputAggregateFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_unit 
								 && (g, source) in group_node 
								 && (ga, p, source) in group_process_node
								 && (g, p) not in group_output__process_fully_inside};
set group_output__process__node__to_connection_Not_in_aggregate :=
    {g in groupOutputNodeFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_connection
								 && (g, source) in group_node
								 && (g, p) not in group_output__process_fully_inside
								 && not sum{(ga, p, source) in group_process_node : ga in groupOutputAggregateFlows} 1};
set group_output__process__connection__to_node_Not_in_aggregate :=
    {g in groupOutputNodeFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_connection
								 && (g, sink) in group_node
								 && (g, p) not in group_output__process_fully_inside
								 && not sum{(ga, p, sink) in group_process_node : ga in groupOutputAggregateFlows} 1};
set group_output__connection_Not_in_aggregate := 
    setof {(g, p, source, sink) in 
	          group_output__process__connection__to_node_Not_in_aggregate
	          union group_output__process__node__to_connection_Not_in_aggregate} (g, p);
set group_output__group_aggregate__process__connection__to_node :=
    {g in groupOutputNodeFlows, ga in groupOutputAggregateFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_connection
								 && (g, sink) in group_node
								 && (ga, p, sink) in group_process_node
								 && not (g, p) in group_output__process_fully_inside};
set group_output__group_aggregate__process__node__to_connection :=
    {g in groupOutputNodeFlows, ga in groupOutputAggregateFlows, (p, source, sink) in process_source_sink_alwaysProcess 
	                             : p in process_connection
								 && (g, source) in group_node
								 && (ga, p, source) in group_process_node
								 && not (g, p) in group_output__process_fully_inside};
set group_output__group_aggregate_Connection :=
    setof {(g, ga, p, source, sink) in 
	          group_output__group_aggregate__process__connection__to_node
	          union group_output__group_aggregate__process__node__to_connection} (g, ga);

set group_output__group_aggregate_Unit_to_group :=
    setof {(g, ga, p, source, sink) in group_output__group_aggregate__process__unit__to_node} (g, ga);

set group_output__group_aggregate_Group_to_unit :=
    setof {(g, ga, p, source, sink) in group_output__group_aggregate__process__node__to_unit} (g, ga);

param p_positive_inflow{n in node, (d,t) in dt: (n, 'no_inflow') not in node__inflow_method} := 
  +(if pdtNodeInflow[n,d,t] >= 0 then pdtNodeInflow[n,d,t] else 0);

param p_negative_inflow{n in node, (d,t) in dt} := 
  +(if pdtNodeInflow[n,d,t] < 0 then pdtNodeInflow[n,d,t] else 0);

param p_entity_existing_capacity_first_solve {e in entity, d in period} :=
  + (if (e, 'reinvest_automatic') in entity__lifetime_method && p_model['solveFirst'] && e in process && not p_process[e, 'virtual_unitsize'] then pdProcess[e, 'existing', d])
  + (if (e, 'reinvest_automatic') in entity__lifetime_method && p_model['solveFirst'] && e in process && p_process[e, 'virtual_unitsize'] then pdProcess[e, 'existing', d] * p_process[e, 'virtual_unitsize'])
  + (if (e, 'reinvest_automatic') in entity__lifetime_method && p_model['solveFirst'] && e in node && not p_node[e, 'virtual_unitsize'] then pdNode[e, 'existing', d])
  + (if (e, 'reinvest_automatic') in entity__lifetime_method && p_model['solveFirst'] && e in node && p_node[e, 'virtual_unitsize'] then pdNode[e, 'existing', d] * p_node[e, 'virtual_unitsize'])
  + (if (e, 'reinvest_choice') in entity__lifetime_method && p_model['solveFirst'] && e in process && not p_process[e, 'virtual_unitsize'] && p_years_d[d] < sum{d_first in period_first} (p_years_d[d_first] + pdEntity_lifetime[e, d_first]) then pdProcess[e, 'existing', d])
  + (if (e, 'reinvest_choice') in entity__lifetime_method && p_model['solveFirst'] && e in process && p_process[e, 'virtual_unitsize'] && p_years_d[d] < sum{d_first in period_first} (p_years_d[d_first] + pdEntity_lifetime[e, d_first]) then pdProcess[e, 'existing', d] * p_process[e, 'virtual_unitsize'])
  + (if (e, 'reinvest_choice') in entity__lifetime_method && p_model['solveFirst'] && e in node && not p_node[e, 'virtual_unitsize'] && p_years_d[d] < sum{d_first in period_first} (p_years_d[d_first] + pdEntity_lifetime[e, d_first]) then pdNode[e, 'existing', d])
  + (if (e, 'reinvest_choice') in entity__lifetime_method && p_model['solveFirst'] && e in node && p_node[e, 'virtual_unitsize'] && p_years_d[d] < sum{d_first in period_first} (p_years_d[d_first] + pdEntity_lifetime[e, d_first]) then pdNode[e, 'existing', d] * p_node[e, 'virtual_unitsize'])
;
param p_entity_existing_capacity_later_solves {e in entity, d in period} :=
  + (if not p_model['solveFirst'] then sum{(e, d_history, d) in edd_history : (e, d_history) in ed_history_realized} p_entity_period_existing_capacity[e, d_history]);
  
param p_entity_all_existing {e in entity, d in period} :=
  + (if p_model['solveFirst'] then p_entity_existing_capacity_first_solve[e, d])
  + (if not p_model['solveFirst'] then p_entity_existing_capacity_later_solves[e, d])
  - (if not p_model['solveFirst'] && e in entityDivest then p_entity_divested[e])
;

param p_entity_existing_count {e in entity, d in period} :=
  + p_entity_all_existing[e, d] 
    / p_entity_unitsize[e];
		  
param p_entity_existing_integer_count {e in entity, d in period} :=
  + round( p_entity_existing_count[e, d] );

param p_entity_previously_invested_capacity {e in entity, d in period} :=
  + (if not p_model['solveFirst'] then sum{(e, d_history, d) in edd_history : (e, d_history) in ed_history_realized} p_entity_period_invested_capacity[e, d_history]);

param p_entity_max_capacity {e in entity, d in period} :=
  + if (e, d) in ed_invest_cumulative
    then ed_cumulative_max_capacity[e, d] 
	else 
      + p_entity_all_existing[e, d]
      + if (e, d) in ed_invest_period && e not in e_invest_total then ed_invest_max_period[e, d] else 0
      + if e in e_invest_total && (e, d) not in ed_invest_period then e_invest_max_total[e] else 0
      + if (e, d) in ed_invest_period && e in e_invest_total then max(ed_invest_max_period[e, d], e_invest_max_total[e]) else 0
      + if (e, 'invest_no_limit') in entity__invest_method then 1000000 else 0    # This may not be enough in all cases, but a very large number could cause numerical issues.
;

param p_entity_max_units {e in entity, d in period} :=
  + p_entity_max_capacity[e, d]
    / p_entity_unitsize[e]
;

set process_source_coeff_zero := {(p, source) in process_source: not p_process_source_coefficient[p, source]};
set process_sink_coeff_zero := {(p, sink) in process_sink: not p_process_sink_coefficient[p, sink]};
set process_source_sink_coeff_zero := {(p, source, sink) in process_source_sink: (p,source) in process_source_coeff_zero || (p,sink) in process_sink_coeff_zero};

param p_flow_max{(p, source, sink, d, t) in peedt} :=
  if (p, source, sink) in process_source_sink_coeff_zero 
  then
    + 1000000   # This may not be enough in all cases, but a very large number could cause numerical issues.
  else
    + (
      if exists{(p, m) in process__method_indirect} 1 && (p, source) in process_source
      then
        + ( if (p, 'min_load_efficiency') in process__ct_method 
          then pdtProcess_slope[p, d, t] + pdtProcess_section[p, d, t]
          else 1 / pdtProcess[p, 'efficiency', d, t]
          ) * p_entity_max_units[p, d]
          / p_process_source_coefficient[p, source]
      else
        + p_entity_max_units[p, d]
      ) 
      * (if (p, sink) in process_sink then p_process_sink_coefficient[p, sink] else 1)
;

param p_flow_min{(p, source, sink, d, t) in peedt} :=
  if (p, source, sink) in process__source__sinkIsNode_2way1var
  then -p_entity_max_units[p, d]
  else 0
;

set process_VRE := {p in process_unit : not (sum{(p, source) in process_source} 1)
                                        && (sum{(p, n, prof, m) in process__node__profile__profile_method : m = 'upper_limit'} 1)};

param p_state_slack_share{(g,n) in group_node, (d,t) in dt: g in group_loss_share} :=
  if (g,'inflow_weighted') in group__loss_share_type then pdtNodeInflow[n,d,t] / (sum{(g,ng) in group_node} pdtNodeInflow[ng,d,t])
  else (if (g,'equal') in group__loss_share_type then 1 / (sum{(g,ng) in group_node} 1) else 0);

param p_storage_state_reference_price{n in nodeState, d in period_in_use}:=
  # if a price is found in the last timestep of the period
  if exists{(n,d2,t2) in ndt_fix_storage_price, (d,t) in period__time_last: (d2,d) in period__branch && (d, t, t2) in dtt_timeline_matching} 1
  then sum{(d2,d) in period__branch, (d,t) in period__time_last, (d, t, t2) in dtt_timeline_matching} p_fix_storage_price[n,d2,t2]
  else (if (n, 'use_reference_price') in node__storage_solve_horizon_method then pdNode[n, 'storage_state_reference_price', d]
  else 0);

param d_obj default 0;
param d_flow {(p, source, sink, d, t) in peedt} default 0;
param d_flow_1_or_2_variable {(p, source, sink, d, t) in peedt} default 0;
param d_flowInvest {(p, d) in pd_invest} default 0;
param d_reserve_upDown_node {(p, r, ud, n, d, t) in prundt} default 0;
param dq_reserve {(r, ud, ng) in reserve__upDown__group, (d, t) in dt} default 0;

#########################
# Variable declarations
var v_flow {(p, source, sink, d, t) in peedt} >= p_flow_min[p, source, sink, d, t], <= p_flow_max[p, source, sink, d, t];
var v_ramp {(p, source, sink) in process_source_sink_ramp, (d, t) in dt} <= p_entity_max_units[p, d];
var v_reserve {(p, r, ud, n, d, t) in prundt : sum{(r, ud, g) in reserve__upDown__group} 1 } >= 0, <= p_entity_max_units[p, d];
var v_state {n in nodeState, (d, t) in dt} >= 0, <= p_entity_max_units[n, d];
var v_online_linear {p in process_online_linear,(d, t) in dt} >=0, <= p_entity_max_units[p, d];
var v_startup_linear {p in process_online_linear, (d, t) in dt} >=0, <= p_entity_max_units[p, d];
var v_shutdown_linear {p in process_online_linear, (d, t) in dt} >=0, <= p_entity_max_units[p, d];
var v_online_integer {p in process_online_integer, (d, t) in dt} >=0, <= p_entity_max_units[p, d], integer;
var v_startup_integer {p in process_online_integer, (d, t) in dt} >=0, <= p_entity_max_units[p, d];
var v_shutdown_integer {p in process_online_integer, (d, t) in dt} >=0, <= p_entity_max_units[p, d];
var v_invest {(e, d) in ed_invest} >= 0, <= p_entity_max_units[e, d];
var v_divest {(e, d) in ed_divest} >= 0, <= p_entity_max_units[e, d];
var vq_state_up {n in (nodeBalance union nodeBalancePeriod), (d, t) in dt} >= 0;
var vq_state_down {n in (nodeBalance union nodeBalancePeriod), (d, t) in dt} >= 0;
var vq_reserve {(r, ud, ng) in reserve__upDown__group, (d, t) in dt} >= 0, <= 1;
var vq_inertia {g in groupInertia, (d, t) in dt} >= 0, <= 1;
var vq_non_synchronous {g in groupNonSync, (d, t) in dt} >= 0;
var vq_capacity_margin {g in groupCapacityMargin, d in period_invest} >= 0, <= ceil((pdGroup[g, 'capacity_margin', d] + group_capacity_for_scaling[g, d]) / group_capacity_for_scaling[g, d]);
var vq_state_up_group {g in group_loss_share, (d,t) in dt} >= 0;

#########################
## Data checks 
printf 'Checking: Eff. data for 1 variable conversions directly from source to sink (and possibly back)\n';
check {(p, m) in process_method, (d,t) in dt : m in method_1var && not (p, 'none') in process__ct_method } pdtProcess[p, 'efficiency', d, t] != 0 ;

printf 'Checking: Efficiency data for 1-way conversions with an online variable\n';
check {(p, m) in process_method, (d,t) in dt : m in method_1way_on} pdtProcess[p, 'efficiency', d, t] != 0;

printf 'Checking: Efficiency data for 2-way linear conversions without online variables\n';
check {(p, m) in process_method, (d,t) in dt : m in method_2way_off} pdtProcess[p, 'efficiency', d, t] != 0;

printf 'Checking: Invalid combinations between conversion/transfer methods and the startup method\n';
check {(p, ct_m, s_m, f_m, m) in process_ct_startup_fork_method} : not (p, ct_m, s_m, f_m, 'not_applicable') in process_ct_startup_fork_method;

printf 'Checking: Is there a timeline connected to a timeblockset\n';
check sum{(tb, tl) in timeblockset__timeline} 1 > 0;

printf 'Checking: Are discount factors set in models with investments and multiple periods\n';
check {d in period : d not in period_first && (sum{(e, d) in ed_invest} 1 || sum{(e, d) in ed_divest} 1)} : p_discount_years[d] != 0;

printf 'Checking: Does a node with has_storage also have has_balance set to yes\n';
check {n in nodeState} : n in nodeBalance;

printf 'Checking: Availability conflicts with storage constraints\n';
check {n in nodeState, (d,t) in period__time_first: (n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method}:
  p_node[n,'storage_state_start'] <= pdtNode[n, 'availability', d, t];
check {n in nodeState, (d,t) in period__time_last: (n, 'fix_end') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method}:
  p_node[n,'storage_state_end'] <= pdtNode[n, 'availability', d, t];

check {n in nodeState, (d,t) in (period__time_first union period__time_last): ((n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)
&& ((n, 'bind_within_solve') in node__storage_binding_method || (n, 'bind_within_period') in node__storage_binding_method)}:
  p_node[n,'storage_state_start'] <= pdtNode[n, 'availability', d, t];
check {n in nodeState, (d,t) in (period__time_first union period__time_last): ((n, 'fix_start_end') in node__storage_start_end_method || (n, 'fix_end') in node__storage_start_end_method)
&& ((n, 'bind_within_solve') in node__storage_binding_method || (n, 'bind_within_period') in node__storage_binding_method)}:
  p_node[n,'storage_state_end'] <= pdtNode[n, 'availability', d, t];

check {n in nodeState, (d,t,t_previous,t_previous_within_block,d_previous,t_previous_within_solve) in dtttdt: 
((n, 'fix_start_end') in node__storage_start_end_method || (n, 'fix_end') in node__storage_start_end_method)
&& (n, 'bind_within_timeblock') in node__storage_binding_method
&& dt_jump[d,t] != 1}:
  p_node[n,'storage_state_end'] <= pdtNode[n, 'availability', d, t] && p_node[n,'storage_state_end'] <= pdtNode[n,'availability', d, t_previous];

check {n in nodeState, (d,t,t_previous,t_previous_within_block,d_previous,t_previous_within_solve) in dtttdt: 
((n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)
&& (n, 'bind_within_timeblock') in node__storage_binding_method
&& dt_jump[d,t] != 1}:
  (p_node[n,'storage_state_start'] <= pdtNode[n, 'availability', d, t] && p_node[n,'storage_state_start'] <= pdtNode[n,'availability', d, t_previous]);

check {n in nodeState, (d,t) in period__time_last: 
  (n, 'use_reference_value') in node__storage_solve_horizon_method 
   && (n, 'fix_end') not in node__storage_start_end_method 
   && (n, 'fix_start_end') not in node__storage_start_end_method
   && (n, 'bind_within_solve') not in node__storage_binding_method
   && (n, 'bind_within_period') not in node__storage_binding_method
   && (n, 'bind_within_timeblock') not in node__storage_binding_method}:
  pdtNode[n,'storage_state_reference_value', d, t] <= pdtNode[n, 'availability', d, t];

printf 'Checking: transfer_method no_losses_no_variable_cost\n';
printf 'is not allowed to a group with non-synchronous constraint\n';
check {g in groupNonSync, (p,source,sink) in process_source_sink:
  (((p,source) in process_source && (g,source) in group_node)
  || ((p,sink) in process_sink && (g,sink) in group_node))
  && (p,g) not in process__group_inside_group_nonSync}: 
    sum{(p, m) in process_method : m in method_2way_1var} 1 < 1;

printf 'Checking: transfer_method no_losses_no_variable_cost\n';
printf 'is not allowed to have other_operational_cost\n';
check {(p,m) in process_method, (d,t) in dt: m in method_2way_1var}: 
  pdtProcess[p, 'other_operational_cost', d, t] = 0;

printf 'Checking: node not in more than one loss of load sharing group\n';
check {n in node}:
  sum{(g,n) in group_node: g in group_loss_share} 1 < 2;

printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for process timeseries \n';
check {(d,t) in period__time_first: exists{(p, param, tb, ts, t2) in process__param__branch__time} 1}:
  exists{(p, param, tb, t, t) in process__param__branch__time, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;
printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for process_inputNode timeseries\n';
check {(d,t) in period__time_first: exists{(p, source, param, tb, ts, t2) in process__source__param__branch__time} 1}:
  exists{(p, source, param, tb, t, t) in process__source__param__branch__time, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;
printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for process_outputNode timeseries\n';
check {(d,t) in period__time_first: exists{(p, sink, param, tb, ts, t2) in process__sink__param__branch__time} 1}:
  exists{(p, sink, param, tb, t, t) in process__sink__param__branch__time, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;
printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for Node inflow timeseries\n';
check{(d,t) in period__time_first: exists{(n, tb, ts, t2) in node__branch__time_inflow} 1 }:
  exists{(n, tb, t, t) in node__branch__time_inflow, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;
printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for Node timeseries\n';
check {(d,t) in period__time_first: exists{(n, param, tb, ts, t2) in node__param__branch__time} 1}:
  exists{(n, param, tb, t, t) in node__param__branch__time, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;
printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for profile timeseries\n';
check {(d,t) in period__time_first: exists{(p, tb, ts, t2) in profile__branch__time} 1}:
  exists{(p, tb, t, t) in profile__branch__time, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;
printf'Checking: If stochastic timeseries data given,\n';
printf'the realized branch is set for the period in stochastic_branches\n';
printf'and the period start time is a branch start time is the timeseries\n';
printf'for reserve timeseries\n';
check {(d,t) in period__time_first: exists{(r, ud, g, param, tb, ts, t2) in reserve__upDown__group__reserveParam__branch__time} 1}:
  exists{(r, ud, g, param, tb, t, t) in reserve__upDown__group__reserveParam__branch__time, (d2,tb) in solve_branch__time_branch: (d2,d) in period__branch} 1;  
printf'Checking that existing capacity is less than cumulative_max_capacity\n';
check {(e, d) in ed_invest_cumulative}:
  p_entity_all_existing[e, d] <= ed_cumulative_max_capacity[e, d];

param setup2 := gmtime() - datetime0 - setup1 - w_calc_slope;
display setup2;
minimize total_cost:
( + sum {(c, n) in commodity_node, (d, t) in dt}
    (+ pdtCommodity[c, 'price', d, t]
	  * (
		  # Buying a commodity (increases the objective function)
		  + sum {(p, n, sink) in process_source_sink_noEff } 
			( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p] )
		  + sum {(p, n, sink) in process_source_sink_eff } (
			  + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
				  * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
				  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
			  + (if (p, 'min_load_efficiency') in process__ct_method then 
				  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
				      + (if p in process_online_integer then v_online_integer[p, d, t])
					)
					* pdtProcess_section[p, d, t]
					* p_entity_unitsize[p]
				)	  
			)		  
		  # Selling to a commodity node (decreases objective function if price is positive)
		  - sum {(p, source, n) in process_source_sink } (
			  + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
			)  
		)
	  * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	)
  + sum {(g, c, n, d, t) in gcndt_co2_price} 
    (+ p_commodity[c, 'co2_content'] * pdtGroup[g, 'co2_price', d, t] 
	  * (
		  # Paying for CO2 (increases the objective function)
		  + sum {(p, n, sink) in process_source_sink_noEff } 
			( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p] )
		  + sum {(p, n, sink) in process_source_sink_eff } (
			  + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
				  * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
				  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
			  + (if (p, 'min_load_efficiency') in process__ct_method then 
				  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
				      + (if p in process_online_integer then v_online_integer[p, d, t])
					)
					* pdtProcess_section[p, d, t]
					* p_entity_unitsize[p]
				)	  
			)		  
		  # Receiving credits for removing CO2 (decreases the objective function)
		  - sum {(p, source, n) in process_source_sink } (
			  + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
			)  
	    )		
	  * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	)
  + sum {(p, d, t) in pdt_online_linear} 
      ( + v_startup_linear[p, d, t] * pdProcess[p, 'startup_cost', d] 
	      * p_entity_unitsize[p] 
		  * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	  )
  + sum {(p, d, t) in pdt_online_integer}
      ( + v_startup_integer[p, d, t] * pdProcess[p, 'startup_cost', d] 
	      * p_entity_unitsize[p] 
		  * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	  )
  + sum {(p, source, sink, d, t) in pssdt_varCost_noEff}
    ( + pdtProcess__source__sink__dt_varCost[p, source, sink, d, t]
	    * v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
        * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	)
  + sum {(p, source, sink, d, t) in pssdt_varCost_eff_unit_source}
    ( - pdtProcess_source[p, source, 'other_operational_cost', d, t]
	    *  
	    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p] 
		    * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
			* (if p in process_unit then 1 / ( p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, source]) else 1)
          + ( if (p, 'min_load_efficiency') in process__ct_method then 
	          + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
			    )
			    * pdtProcess_section[p, d, t]
			    * p_entity_unitsize[p]
			)
		)	  
        * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	)
  + sum {(p, source, sink, d, t) in pssdt_varCost_eff_unit_sink}
    ( + pdtProcess_sink[p, sink, 'other_operational_cost', d, t]
	    * v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
        * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	)
  + sum {(p, source, sink, d, t) in pssdt_varCost_eff_connection}
    ( + pdtProcess[p, 'other_operational_cost', d, t]
 	   * v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
       * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
	)
#  + sum {(p, source, sink, m) in process__source__sink__ramp_method, (d, t) in dt : m in ramp_cost_method}
#    ( + v_ramp[p, source, sink, d, t] * p_entity_unitsize[p] * pProcess_source_sink[p, source, sink, 'ramp_cost'] ) * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d]
  + sum {g in groupInertia, (d, t) in dt} pdt_branch_weight[d,t] * vq_inertia[g, d, t] * pdGroup[g, 'inertia_limit', d]
                                            * pdGroup[g, 'penalty_inertia', d] * step_duration[d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d]
  + sum {g in groupNonSync, (d, t) in dt} pdt_branch_weight[d,t] * vq_non_synchronous[g, d, t] * group_capacity_for_scaling[g, d]
                                            * pdGroup[g, 'penalty_non_synchronous', d]  * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d]
  + sum {n in nodeBalance union nodeBalancePeriod, (d, t) in dt} pdt_branch_weight[d,t] * vq_state_up[n, d, t] * node_capacity_for_scaling[n, d]
                                            * pdtNode[n, 'penalty_up', d, t]  * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d]
  + sum {n in nodeBalance union nodeBalancePeriod, (d, t) in dt} pdt_branch_weight[d,t] * vq_state_down[n, d, t] * node_capacity_for_scaling[n, d]
                                            * pdtNode[n, 'penalty_down', d, t] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d]
  + sum {(r, ud, ng) in reserve__upDown__group, (d, t) in dt} pdt_branch_weight[d,t] * vq_reserve[r, ud, ng, d, t]  * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t]
                                            * p_reserve_upDown_group[r, ud, ng, 'penalty_reserve']  * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d]

  - sum {n in nodeState, (d, t) in period__time_last : (n, 'use_reference_price') in node__storage_solve_horizon_method && d in period_last}
    (+ p_storage_state_reference_price[n,d]
        * v_state[n, d, t] * p_entity_unitsize[n]
		 * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] * pdt_branch_weight[d,t]
    )
  + sum {e in entity, d in period_in_use}  # This is constant term and will be dropped by the solver. Here for completeness.
    + p_entity_all_existing[e, d]
      * ( + (if e in node then pdNode[e, 'fixed_cost', d] * 1000)
	      + (if e in process then pdProcess[e, 'fixed_cost', d] * 1000)
		)
	  * p_discount_factor_operations_yearly[d] * pd_branch_weight[d]
  + sum {(e, d) in ed_invest} 
    # Currently investment happens only on the realized branch and the rest get them as existing.
    # Only one period investment is supported with stochastics
    # The branch weight should be added if this is changed.
      + v_invest[e, d]
      * p_entity_unitsize[e]
      * ed_entity_annual_discounted[e, d]
  - sum {(e, d) in ed_divest} 
      + v_divest[e, d]
      * p_entity_unitsize[e]
      * ed_entity_annual_divest_discounted[e, d]
  + sum {g in groupCapacityMargin, d in period_invest}
    + vq_capacity_margin[g, d] * group_capacity_for_scaling[g, d]
	  * pdGroup[g, 'penalty_capacity_margin', d]
	  * p_discount_factor_operations_yearly[d]
) * scale_the_objective
;
param w_total_cost := gmtime() - datetime0 - setup1 - w_calc_slope - setup2;
display w_total_cost;

# Energy balance in each node  
s.t. nodeBalance_eq {c in solve_current, n in nodeBalance, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} :
  + (if n in nodeState && (n, 'bind_forward_only') in node__storage_binding_method && not ((d, t) in period__time_first && d in period_first_of_solve) then (v_state[n, d, t] -  v_state[n, d_previous, t_previous_within_solve]) * p_entity_unitsize[n] / p_hole_multiplier[c] )
  + (if n in nodeState && (n, 'bind_within_solve') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d_previous, t_previous_within_solve]) * p_entity_unitsize[n]  / p_hole_multiplier[c] )
  + (if n in nodeState && (n, 'bind_within_period') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d, t_previous]) * p_entity_unitsize[n]  / p_hole_multiplier[c] )
  + (if n in nodeState && (n, 'bind_within_timeblock') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d, t_previous_within_block]) * p_entity_unitsize[n] )
  + (if n in nodeState && (d, t) in period__time_first && d in period_first_of_solve && not p_nested_model['solveFirst'] then (v_state[n,d,t] * p_entity_unitsize[n] - p_roll_continue_state[n])) 
  + (if n in nodeState && (n, 'bind_forward_only') in node__storage_binding_method && (d, t) in period__time_first && d in period_first_of_solve && p_nested_model['solveFirst'] 
    && ((n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)
    then (+ v_state[n,d,t] * p_entity_unitsize[n] - p_node[n,'storage_state_start'] * 
          (+ p_entity_all_existing[n, d]
          + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
          - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
	  )))
  =
  # n is sink
  + sum {(p, source, n) in process_source_sink} (
      + v_flow[p, source, n, d, t] * p_entity_unitsize[p] * step_duration[d, t]
	)  
  # n is source
  - sum {(p, n, sink) in process_source_sink_eff } ( 
      + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
      + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
			    * pdtProcess_section[p, d, t]
				* p_entity_unitsize[p]
		)
    ) * step_duration[d, t]		
  - sum {(p, n, sink) in process_source_sink_noEff} 
    ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
    ) * step_duration[d, t]
  + (if (n, 'no_inflow') not in node__inflow_method then pdtNodeInflow[n, d, t])
  - (if n in nodeSelfDischarge then 
      + v_state[n, d, t] 
	    * (-1 + (1 + pdtNode[n, 'self_discharge_loss', d, t]) ** step_duration[d, t])
		  * p_entity_unitsize[n]
    )
  + vq_state_up[n, d, t] * node_capacity_for_scaling[n, d]
  - vq_state_down[n, d, t] * node_capacity_for_scaling[n, d]
;

# Energy balance within period in each node  
s.t. nodeBalancePeriod_eq {c in solve_current, n in nodeBalancePeriod, d in period : n not in nodeState} :
  0
  =
  # n is sink
  + sum {(p, source, n) in process_source_sink, (d, t) in dt} (
      + v_flow[p, source, n, d, t] * p_entity_unitsize[p] * step_duration[d, t]
	)  
  # n is source
  - sum {(p, n, sink) in process_source_sink_eff, (d, t) in dt } ( 
      + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
      + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
			    * pdtProcess_section[p, d, t]
				* p_entity_unitsize[p]
		)
    ) * step_duration[d, t]		
  - sum {(p, n, sink) in process_source_sink_noEff, (d, t) in dt} 
    ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
    ) * step_duration[d, t]
  + pdNode[n, 'annual_flow', d] * period_share_of_year[d]
  + sum {(d, t) in dt} vq_state_up[n, d, t] * node_capacity_for_scaling[n, d]
  - sum {(d, t) in dt} vq_state_down[n, d, t] * node_capacity_for_scaling[n, d]
;
param balance := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost;
display balance;

s.t. reserveBalance_timeseries_eq {(r, ud, ng, r_m) in reserve__upDown__group__method_timeseries, (d, t) in dt} :
  + sum {(p, r, ud, n) in process_reserve_upDown_node_active 
	      : ( sum{(p, m) in process_method : m not in method_1var_per_way} 1   ## not 1var_per_way and source; not 1var_per_way and sink; 1var_per_way and sink 
		        || (p, n) in process_sink
			)
		    && (ng, n) in group_node 
		    && (r, ud, ng) in reserve__upDown__group} 
	    ( v_reserve[p, r, ud, n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, ud, n, 'reliability']
	    )
  + sum {(p, r, ud, n) in process_reserve_upDown_node_active                   ## 1var_per_way and source  
		  : ( sum{(p, m) in process_method : m in method_1var_per_way} 1 
		        && (p, n) in process_source
			)
		    && (ng, n) in group_node 
		    && (r, ud, ng) in reserve__upDown__group} 
	    ( v_reserve[p, r, ud, n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, ud, n, 'reliability']
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		)
  + vq_reserve[r, ud, ng, d, t] * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t]
  >=
  + pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t]
;

s.t. reserveBalance_dynamic_eq{(r, ud, ng, r_m) in reserve__upDown__group__method_dynamic, (d, t) in dt} :
  + sum {(p, r, ud, n) in process_reserve_upDown_node_active 
	      : ( sum{(p, m) in process_method : m not in method_1var_per_way} 1   ## not 1var_per_way and source; not 1var_per_way and sink; 1var_per_way and sink
		        || (p, n) in process_sink
			)
		    && (ng, n) in group_node 
		    && (r, ud, ng) in reserve__upDown__group} 
	    ( v_reserve[p, r, ud, n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, ud, n, 'reliability']
	    )
  + sum {(p, r, ud, n) in process_reserve_upDown_node_active               
		  : ( sum{(p, m) in process_method : m in method_1var_per_way} 1       ## 1var_per_way and source
		        && (p, n) in process_source
			)
		    && (ng, n) in group_node 
		    && (r, ud, ng) in reserve__upDown__group} 
	    ( v_reserve[p, r, ud, n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, ud, n, 'reliability']
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		)
  + vq_reserve[r, ud, ng, d, t] * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t]
  >=
  + sum {(p, r, ud, n) in process_reserve_upDown_node_increase_reserve_ratio : (ng, n) in group_node 
          && (r, ud, ng) in reserve__upDown__group}
	   ( + sum{(p, source, n) in process_source_sink} v_flow[p, source, n, d, t] * p_entity_unitsize[p] * p_process_reserve_upDown_node[p, r, ud, n, 'increase_reserve_ratio']
	     + sum{(p, n, sink) in process_source_sink_noEff} v_flow[p, n, sink, d, t] * p_entity_unitsize[p] * p_process_reserve_upDown_node[p, r, ud, n, 'increase_reserve_ratio']
	     + sum{(p, n, sink) in process_source_sink_eff} v_flow[p, n, sink, d, t] * p_entity_unitsize[p] * p_process_reserve_upDown_node[p, r, ud, n, 'increase_reserve_ratio']
	                                                    * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
	   )
  + sum {(n, ng) in group_node : p_reserve_upDown_group[r, ud, ng, 'increase_reserve_ratio']}
	   (pdtNodeInflow[n, d, t] * p_reserve_upDown_group[r, ud, ng, 'increase_reserve_ratio'])/ step_duration[d, t]
;

s.t. reserveBalance_up_n_1_eq{(r, 'up', ng, r_m) in reserve__upDown__group__method_n_1, p_n_1 in process_large_failure, (d, t) in dt :
  sum{(p_n_1, sink) in process_sink : (ng, sink) in group_node} 1 } :
  + sum {(p, r, 'up', n) in process_reserve_upDown_node_active 
	      : p <> p_n_1
		    && ( sum{(p, m) in process_method : m not in method_1var_per_way} 1  ## not 1var_per_way and source; not 1var_per_way and sink; 1var_per_way and sink
		         || (p, n) in process_sink
			   )
		    && (ng, n) in group_node 
		    && (r, 'up', ng) in reserve__upDown__group
		} 
	    ( v_reserve[p, r, 'up', n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, 'up', n, 'reliability']
	    )
  + sum {(p, r, 'up', n) in process_reserve_upDown_node_active                 
		  : p <> p_n_1
 		    && ( sum{(p, m) in process_method : m in method_1var_per_way} 1      ## 1var_per_way and source
		         && (p, n) in process_source
			   )
		    && (ng, n) in group_node 
		    && (r, 'up', ng) in reserve__upDown__group
		} 
	    ( v_reserve[p, r, 'up', n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, 'up', n, 'reliability']
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		)
  + vq_reserve[r, 'up', ng, d, t] * pdtReserve_upDown_group[r, 'up', ng, 'reservation', d, t]
  >=
  + sum{(p_n_1, source, n) in process_source_sink : (ng, n) in group_node} 
      + v_flow[p_n_1, source, n, d, t] * p_entity_unitsize[p_n_1]
	    * p_process_reserve_upDown_node[p_n_1, r, 'up', n, 'large_failure_ratio']
;

s.t. reserveBalance_down_n_1_eq{(r, 'down', ng, r_m) in reserve__upDown__group__method_n_1, p_n_1 in process_large_failure, (d, t) in dt :
  sum{(p_n_1, source) in process_source : (ng, source) in group_node} 1 } :
  + sum {(p, r, 'down', n) in process_reserve_upDown_node_active 
	      : p <> p_n_1
		    && ( sum{(p, m) in process_method : m not in method_1var_per_way} 1  ## not 1var_per_way and source; not 1var_per_way and sink; 1var_per_way and sink
		         || (p, n) in process_sink
			   )
		    && (ng, n) in group_node 
		    && (r, 'down', ng) in reserve__upDown__group
		} 
	    ( v_reserve[p, r, 'down', n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, 'down', n, 'reliability']
	    )
  + sum {(p, r, 'down', n) in process_reserve_upDown_node_active                 
		  : p <> p_n_1
 		    && ( sum{(p, m) in process_method : m in method_1var_per_way} 1      ## 1var_per_way and source
		         && (p, n) in process_source
			   )
		    && (ng, n) in group_node 
		    && (r, 'down', ng) in reserve__upDown__group
		} 
	    ( v_reserve[p, r, 'down', n, d, t] * p_entity_unitsize[p]
	      * p_process_reserve_upDown_node[p, r, 'down', n, 'reliability']
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		)
  + vq_reserve[r, 'down', ng, d, t] * pdtReserve_upDown_group[r, 'down', ng, 'reservation', d, t]
  >=
  + sum{(p_n_1, n, sink) in process_source_sink_noEff : (ng, n) in group_node} 
      + v_flow[p_n_1, n, sink, d, t] * p_entity_unitsize[p_n_1]
	    * p_process_reserve_upDown_node[p_n_1, r, 'down', n, 'large_failure_ratio']
  + sum{(p_n_1, n, sink) in process_source_sink_eff : (ng, n) in group_node } 
      + v_flow[p_n_1, n, sink, d, t] * p_entity_unitsize[p_n_1]
	    * p_process_reserve_upDown_node[p_n_1, r, 'down', n, 'large_failure_ratio']
	    * (if (p_n_1, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p_n_1, d, t] else 1 / pdtProcess[p_n_1, 'efficiency', d, t])
;
param reserves := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance;
display reserves;

# Indirect efficiency conversion - there is more than one variable. Direct conversion does not have an equation - it's directly in the nodeBalance_eq.
s.t. conversion_indirect {(p, m) in process__method_indirect, (d, t) in dt} :
  + sum {source in entity : (p, source) in process_source} 
    ( + v_flow[p, source, p, d, t] * p_entity_unitsize[p]
  	      * p_process_source_coefficient[p, source]
	)
  =
  + sum {sink in entity : (p, sink) in process_sink && p_process_sink_coefficient[p,sink] != 0} 
    ( + v_flow[p, p, sink, d, t] * p_entity_unitsize[p]
	      / p_process_sink_coefficient[p, sink]
	)
	  * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
  + (if (p, 'min_load_efficiency') in process__ct_method then 
			( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			  + (if p in process_online_integer then v_online_integer[p, d, t])
			)
            * pdtProcess_section[p, d, t] * p_entity_unitsize[p])
;
param indirect := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves;
display indirect;

s.t. profile_flow_upper_limit {(p, source, sink, f, 'upper_limit') in process__source__sink__profile__profile_method, (d, t) in dt} :
  + ( + v_flow[p, source, sink, d, t]
      + sum{(p, r, 'up', sink) in process_reserve_upDown_node} v_reserve[p, r, 'up', sink, d, t]
	)
  <=
  + pdtProfile[f, d, t]
    * ( + p_entity_existing_count[p, d]
        + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
	  )
      * pdtProcess[p, 'availability', d, t]
;

s.t. profile_flow_lower_limit {(p, source, sink, f, 'lower_limit') in process__source__sink__profile__profile_method, (d, t) in dt} :
  + ( + v_flow[p, source, sink, d, t]
      - sum{(p, r, 'down', sink) in process_reserve_upDown_node} v_reserve[p, r, 'down', sink, d, t]
    )
  >=
  + pdtProfile[f, d, t]
    * ( + p_entity_existing_count[p, d]
        + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
	  )
      * pdtProcess[p, 'availability', d, t]
;

s.t. profile_flow_fixed {(p, source, sink, f, 'fixed') in process__source__sink__profile__profile_method, (d, t) in dt} :
  + v_flow[p, source, sink, d, t]
  =
  + pdtProfile[f, d, t]
    * ( + p_entity_existing_count[p, d]
        + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
	  )
      * pdtProcess[p, 'availability', d, t]
;

s.t. profile_state_upper_limit {(n, f, 'upper_limit') in node__profile__profile_method, (d, t) in dt} :
  + v_state[n, d, t]
  <=
  + pdtProfile[f, d, t]
    * ( + p_entity_existing_count[n, d]
        + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest]
        - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest]
	  )
      * pdtNode[n, 'availability', d, t]
;

s.t. profile_state_lower_limit {(n, f, 'lower_limit') in node__profile__profile_method, (d, t) in dt} :
  + v_state[n, d, t]
  >=
  + pdtProfile[f, d, t]
    * ( + p_entity_existing_count[n, d]
        + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest]
        - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest]
	  )
      * pdtNode[n, 'availability', d, t]
;

s.t. profile_state_fixed {(n, f, 'fixed') in node__profile__profile_method, (d, t) in dt} :
  + v_state[n, d, t]
  =
  + pdtProfile[f, d, t]
    * ( + p_entity_existing_count[n, d]
        + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest]
        - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest]
	  )
      * pdtNode[n, 'availability', d, t]
;


s.t. storage_state_start_binding {n in nodeState, (d, t) in period__time_first
     : p_nested_model['solveFirst'] && (n, 'bind_forward_only') not in node__storage_binding_method
	 && d in period_first 
	 && ((n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)} :
  + v_state[n, d, t] * p_entity_unitsize[n]
  =
  + p_node[n,'storage_state_start']
    * ( + p_entity_all_existing[n, d]
        + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
        - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
	  )
;

s.t. storage_state_end {n in nodeState, (d, t) in period__time_last 
     : p_nested_model['solveLast'] 
	 && d in period_last 
	 && ((n, 'fix_end') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)
   && sum{(d2,d) in period__branch, (n,d2,t2) in ndt_fix_storage_quantity: (d, t, t2) in dtt_timeline_matching} 1 = 0
   && sum{(d2,d) in period__branch, (n,d2,t2) in ndt_fix_storage_price: (d, t, t2) in dtt_timeline_matching} 1 = 0
   && sum{(d2,d) in period__branch, (n,d2,t2) in ndt_fix_storage_usage: (d, t, t2) in dtt_timeline_matching} 1 = 0} :
  + v_state[n, d, t] * p_entity_unitsize[n]
  =
  + p_node[n,'storage_state_end']
    * ( + p_entity_all_existing[n, d]
        + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
        - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
	  )
;

#Storage state fix quantity for timesteps
s.t. node_balance_fix_quantity_eq_lower {n in n_fix_storage_quantity, (d,t) in period__time_last, (d2,d) in period__branch: d in period_last && sum{(n,d2,t2) in ndt_fix_storage_quantity: (d, t, t2) in dtt_timeline_matching} 1}:
  + v_state[n,d,t]* p_entity_unitsize[n] 
  = 
  + sum{(d, t, t2) in dtt_timeline_matching} p_fix_storage_quantity[n,d2,t2];

#Storage usage fix for timesteps 

s.t. storage_usage_fix{n in n_fix_storage_usage, (d,t) in period__time_last, (d2,d) in period__branch: 
      d in period_last && sum{(n,d2,t2) in ndt_fix_storage_usage: (d, t, t2) in dtt_timeline_matching} 1}:
  # n is sink
  - sum {(p, source, n) in process_source_sink, (d,t3) in dt} (
      + v_flow[p, source, n, d, t3] * p_entity_unitsize[p] * step_duration[d, t3]
  )  
  # n is source
  + sum {(p, n, sink) in process_source_sink_eff, (d,t3) in dt} ( 
      + v_flow[p, n, sink, d, t3] * p_entity_unitsize[p]
        * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t3] else 1 / pdtProcess[p, 'efficiency', d, t3])
      * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
      + (if (p, 'min_load_efficiency') in process__ct_method then 
        + ( + (if p in process_online_linear then v_online_linear[p, d, t3]) 
            + (if p in process_online_integer then v_online_integer[p, d, t3])
        )
          * pdtProcess_section[p, d, t3]
        * p_entity_unitsize[p]
    )
    ) * step_duration[d, t3]		
  + sum {(p, n, sink) in process_source_sink_noEff, (d,t3) in dt} 
    ( + v_flow[p, n, sink, d, t3] * p_entity_unitsize[p]
    ) * step_duration[d, t3]
  <= 
  + sum{(n,d2,t2) in ndt_fix_storage_usage: exists{(d, t3, t2) in dtt_timeline_matching} 1} p_fix_storage_usage[n,d2,t2]
  ;


s.t. storage_usage_fix_realized{n in n_fix_storage_usage, (d,t) in period__time_last, (d2,d) in period__branch: 
      d in period_last && sum{(n,d2,t2) in ndt_fix_storage_usage: (d, t, t2) in dtt_timeline_matching} 1}:
  # n is sink
  - sum {(p, source, n) in process_source_sink, (d2,t3) in dt_realize_dispatch} (
      + v_flow[p, source, n, d, t3] * p_entity_unitsize[p] * step_duration[d, t3]
  )  
  # n is source
  + sum {(p, n, sink) in process_source_sink_eff, (d2,t3) in dt_realize_dispatch} ( 
      + v_flow[p, n, sink, d, t3] * p_entity_unitsize[p]
        * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t3] else 1 / pdtProcess[p, 'efficiency', d, t3])
      * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
      + (if (p, 'min_load_efficiency') in process__ct_method then 
        + ( + (if p in process_online_linear then v_online_linear[p, d, t3]) 
            + (if p in process_online_integer then v_online_integer[p, d, t3])
        )
          * pdtProcess_section[p, d, t3]
        * p_entity_unitsize[p]
    )
    ) * step_duration[d, t3]		
  + sum {(p, n, sink) in process_source_sink_noEff, (d2,t3) in dt_realize_dispatch} 
    ( + v_flow[p, n, sink, d, t3] * p_entity_unitsize[p]
    ) * step_duration[d, t3]
  <= 
  + sum{(n,d2,t2) in ndt_fix_storage_usage: exists{(d, t3, t2) in dtt_timeline_matching: (d2,t3) in dt_realize_dispatch} 1} p_fix_storage_usage[n,d2,t2]
  ;

s.t. storage_state_solve_horizon_reference_value {n in nodeState, (d, t) in period__time_last
     : d in period_last
	 && ((n, 'use_reference_value') in node__storage_solve_horizon_method 
   && (n, 'fix_end') not in node__storage_start_end_method 
   && (n, 'fix_start_end') not in node__storage_start_end_method
   && (n, 'bind_within_solve') not in node__storage_binding_method
   && (n, 'bind_within_period') not in node__storage_binding_method
   && (n, 'bind_within_timeblock') not in node__storage_binding_method
   && sum{(d2,d) in period__branch, (d, t, t2) in dtt_timeline_matching: n in n_fix_storage_price} 1 = 0
   && sum{(d2,d) in period__branch, (d, t, t2) in dtt_timeline_matching: n in n_fix_storage_quantity} 1 = 0
   && sum{(d2,d) in period__branch, (d, t, t2) in dtt_timeline_matching: n in n_fix_storage_usage} 1 = 0)} :
  + v_state[n, d, t] * p_entity_unitsize[n]
  =
  + pdtNode[n,'storage_state_reference_value', d, t]
    * ( + p_entity_all_existing[n, d]
        + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
        - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
	  )
;

s.t. constraint_greater_than {(c, 'greater_than') in constraint__sense, (d, t) in dt} :
  + sum {(p, source, sink) in process_source_sink : (p, source, c) in process_node_flow_constraint}
    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	      * p_process_node_constraint_flow_coefficient[p, source, c]
	)
  + sum {(p, source, sink) in process_source_sink : (p, sink, c) in process_node_flow_constraint}
    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	      * p_process_node_constraint_flow_coefficient[p, sink, c]
	)
  + sum {(n, c) in node_state_constraint}
    ( + v_state[n, d, t]
	      * p_node_constraint_state_coefficient[n, c]
		  * p_entity_unitsize[n]
	)
  + sum {(n, c) in node_capacity_constraint : d in period_invest}
    ( ( + sum{(n, d_invest, d) in edd_invest} v_invest[n, d]
	    - sum{(n, d_divest) in nd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d]
	  )
	  * p_node_constraint_capacity_coefficient[n, c]
    * p_entity_unitsize[n]
	)
  + sum {(p, c) in process_capacity_constraint : d in period_invest}
    ( ( + sum{(p, d_invest, d) in edd_invest} v_invest[p, d]
	    - sum{(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d]
	  )
	  * p_process_constraint_capacity_coefficient[p, c]
    * p_entity_unitsize[p]
	)
  >=
  + p_constraint_constant[c]
;
	
s.t. process_constraint_less_than {(c, 'less_than') in constraint__sense, (d, t) in dt} :
  + sum {(p, source, sink) in process_source_sink : (p, source, c) in process_node_flow_constraint}
    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	      * p_process_node_constraint_flow_coefficient[p, source, c]
	)
  + sum {(p, source, sink) in process_source_sink : (p, sink, c) in process_node_flow_constraint}
    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	      * p_process_node_constraint_flow_coefficient[p, sink, c]
	)
  + sum {(n, c) in node_state_constraint}
    ( + v_state[n, d, t]
	      * p_node_constraint_state_coefficient[n, c]
		  * p_entity_unitsize[n]
	)
  + sum {(n, c) in node_capacity_constraint : d in period_invest}
    ( ( + sum{(n, d_invest, d) in edd_invest} v_invest[n, d]
	    - sum{(n, d_divest) in nd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d]
	  )
	  * p_node_constraint_capacity_coefficient[n, c]
    * p_entity_unitsize[n]
	)
  + sum {(p, c) in process_capacity_constraint : d in period_invest}
    ( ( + sum{(p, d_invest, d) in edd_invest} v_invest[p, d]
	    - sum{(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d]
	  )
	  * p_process_constraint_capacity_coefficient[p, c]
    * p_entity_unitsize[p]
	)
  <=
  + p_constraint_constant[c]
;

s.t. process_constraint_equal {(c, 'equal') in constraint__sense, (d, t) in dt} :
  + sum {(p, source, sink) in process_source_sink : (p, source, c) in process_node_flow_constraint}
    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	      * p_process_node_constraint_flow_coefficient[p, source, c]
	)
  + sum {(p, source, sink) in process_source_sink : (p, sink, c) in process_node_flow_constraint}
    ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	      * p_process_node_constraint_flow_coefficient[p, sink, c]
	)
  + sum {(n, c) in node_state_constraint}
    ( + v_state[n, d, t]
	      * p_node_constraint_state_coefficient[n, c]
		  * p_entity_unitsize[n]
	)
  + sum {(n, c) in node_capacity_constraint : d in period_invest}
    ( ( + sum{(n, d_invest, d) in edd_invest} v_invest[n, d]
	    - sum{(n, d_divest) in nd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d]
	  )
	  * p_node_constraint_capacity_coefficient[n, c]
    * p_entity_unitsize[n]
	)
  + sum {(p, c) in process_capacity_constraint : d in period_invest}
    ( ( + sum{(p, d_invest, d) in edd_invest} v_invest[p, d]
	    - sum{(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d]
	  )
	  * p_process_constraint_capacity_coefficient[p, c]
    * p_entity_unitsize[p]
	)
  =
  + p_constraint_constant[c]
;


s.t. maxState {n in nodeState, (d, t) in dt} :
  + v_state[n, d, t] * p_entity_unitsize[n]
  <=
  + ( 
      + p_entity_all_existing[n, d]
      + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
      - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
    ) 
	* pdtNode[n, 'availability', d, t]
;

s.t. maxToSink {(p, source, sink) in process__source__sinkIsNode, (d, t) in dt : p_process_sink_coefficient[p, sink]} :
  + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
  + sum {r in reserve : (p, r, 'up', sink) in process_reserve_upDown_node_active} v_reserve[p, r, 'up', sink, d, t] * p_entity_unitsize[p]
  <=
  + ( if p not in process_online then
      + ( + p_entity_all_existing[p, d]
          + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
          - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	    )	
		* pdtProcess[p, 'availability', d, t]
		* p_process_sink_coefficient[p, sink]
	)
  + ( if p in process_online_linear then
      + p_process_sink_coefficient[p, sink]
        * v_online_linear[p, d, t]
		* p_entity_unitsize[p]
        * pdtProcess[p, 'availability', d, t]
    ) 
  + ( if p in process_online_integer then
      + p_process_sink_coefficient[p, sink]
        * v_online_integer[p, d, t]
		* p_entity_unitsize[p]
        * pdtProcess[p, 'availability', d, t]
    ) 
;

s.t. minToSink {(p, source, sink) in process__source__sinkIsNode_not2way1var, (d, t) in dt : p_process_sink_coefficient[p, sink]} :
  + v_flow[p, source, sink, d, t] >= 0
;

s.t. minToSink_minload {(p, source, sink) in process__source__sinkIsNode_not2way1var, (d, t) in dt : p_process_sink_coefficient[p, sink] && p in process_online} :
  + sum{(p, source, sink2) in process__source__sinkIsNode_not2way1var} v_flow[p, source, sink2, d, t] 
  >=
  + (if p in process_online_linear then v_online_linear[p, d, t] * p_process[p, 'min_load'] * p_process_sink_coefficient[p, sink] else 0)
  + (if p in process_online_integer then v_online_integer[p, d, t] * p_process[p, 'min_load'] * p_process_sink_coefficient[p, sink] else 0)
;

s.t. maxFromSource {(p, source, sink) in process__sourceIsNode__sink_1way_noSinkOrMoreThan1Source, (d, t) in dt : p_process_source_coefficient[p, source]} :
  + v_flow[p, source, sink, d, t] * p_entity_unitsize[p] * p_process_source_coefficient[p, source] 
  <=
  + ( if p not in process_online then
      + ( + p_entity_all_existing[p, d]
          + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
          - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	    )	
	    * pdtProcess[p, 'availability', d, t]
	)
  + ( if p in process_online_linear then
      + v_online_linear[p, d, t]
		* p_entity_unitsize[p]
        * pdtProcess[p, 'availability', d, t]
	)
  + ( if p in process_online_integer then
      + v_online_integer[p, d, t]
		* p_entity_unitsize[p]
        * pdtProcess[p, 'availability', d, t]
    ) 
;

# Force source flows from 1-way processes with more than 1 source to be at least 0 (conversion equation does not do it)
s.t. minFromSource {(p, source, sink) in process__sourceIsNode__sink_1way_noSinkOrMoreThan1Source, (d, t) in dt : p_process_source_coefficient[p, source]} :
  + v_flow[p, source, sink, d, t] * p_process_source_coefficient[p, source] >= 0
;

s.t. minFromSource_minload {(p, source, sink) in process__sourceIsNode__sink_1way_noSinkOrMoreThan1Source, (d, t) in dt : p_process_source_coefficient[p, source] && p in process_online} :
  +  sum{(p, source2, sink) in process__sourceIsNode__sink_1way_noSinkOrMoreThan1Source} v_flow[p, source2, sink, d, t] * p_process_source_coefficient[p, source]
  >=
  + (if p in process_online_linear then v_online_linear[p, d, t] * p_process[p, 'min_load'] else 0)
  + (if p in process_online_integer then v_online_integer[p, d, t] * p_process[p, 'min_load'] else 0)
;

# Special equation to limit the 1variable connection on the negative transfer
s.t. minToSink_1var {(p, source, sink) in process__source__sinkIsNode_2way1var, (d, t) in dt : p_process_sink_coefficient[p, sink]} :
  + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
  >=
  - ( if p not in process_online then
      + p_process_sink_coefficient[p, sink] 
        * ( + p_entity_all_existing[p, d]
            + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
            - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	      )	
	)
  - ( if p in process_online_linear then
      + p_process_sink_coefficient[p, sink]
        * v_online_linear[p, d, t] 
		* p_entity_unitsize[p]
    )  
  - ( if p in process_online_integer then
      + p_process_sink_coefficient[p, sink]
        * v_online_integer[p, d, t] 
		* p_entity_unitsize[p]
    )  
;

# Special equations for the method with 2 variables presenting a direct 2way connection between source and sink (without the process)
s.t. maxToSource {(p, sink, source) in process_sink_toSource, (d, t) in dt : p_process_source_coefficient[p, source]} :
  + v_flow[p, sink, source, d, t] * p_entity_unitsize[p]
  + sum {r in reserve : (p, r, 'up', source) in process_reserve_upDown_node_active} v_reserve[p, r, 'up', source, d, t] * p_entity_unitsize[p]
  <=
  + ( if p not in process_online then
      + p_process_source_coefficient[p, source] 
        * ( + p_entity_all_existing[p, d]
            + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
            - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	      ) 
		  * pdtProcess[p, 'availability', d, t]
	)
  + ( if p in process_online_linear then
      + p_process_source_coefficient[p, source]
        * v_online_linear[p, d, t] 
		* p_entity_unitsize[p]
        * pdtProcess[p, 'availability', d, t]
    )  
  + ( if p in process_online_integer then
      + p_process_source_coefficient[p, source]
        * ( 
		    + p_entity_existing_integer_count[p, d]
          + (if d in period_invest then v_invest[p, d] else 0)			
			- v_online_integer[p, d, t]   # Using binary online variable as a switch between directions
		  )   
		* p_entity_unitsize[p]
        * pdtProcess[p, 'availability', d, t]
    )  
;

s.t. minToSource {(p, source, sink) in process__source__sinkIsNode_2way2var, (d, t) in dt : p_process_source_coefficient[p, source]} :
  + v_flow[p, sink, source, d, t]
  >=
  + (if p in process_online_linear then v_online_linear[p, d, t] * p_process[p, 'min_load'] * p_process_source_coefficient[p, source] else 0)
  + (if p in process_online_integer then v_online_integer[p, d, t] * p_process[p, 'min_load'] * p_process_source_coefficient[p, source] else 0)
;

s.t. maxOnline {p in process_online, (d, t) in dt} :
  + (if p in process_online_linear then v_online_linear[p, d, t])
  + (if p in process_online_integer then v_online_integer[p, d, t])
  <=
  + p_entity_all_existing[p, d] / p_entity_unitsize[p]
  + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest]
  - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
;

s.t. online__startup_linear {p in process_online_linear, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} :
  + v_startup_linear[p, d, t]
  >=
  + v_online_linear[p, d, t] 
  - v_online_linear[p, d_previous, t_previous_within_solve]
;

s.t. online__startup_integer {p in process_online_integer, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} :
  + v_startup_integer[p, d, t]
  >=
  + v_online_integer[p, d, t] 
  - v_online_integer[p, d_previous, t_previous_within_solve]
;

s.t. maxStartup {p in process_online, (d, t) in dt} :
  + (if p in process_online_linear then v_startup_linear[p, d, t])
  + (if p in process_online_integer then v_startup_integer[p, d, t])
  <=
  + p_entity_all_existing[p, d] / p_entity_unitsize[p]
  + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest]
  - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
;

s.t. online__shutdown_linear {p in process_online_linear, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} :
  + v_shutdown_linear[p, d, t]
  >=
  - v_online_linear[p, d, t] 
  + v_online_linear[p, d_previous, t_previous_within_solve]
;

s.t. online__shutdown_integer {p in process_online_integer, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} :
  + v_shutdown_integer[p, d, t]
  >=
  - v_online_integer[p, d, t] 
  + v_online_integer[p, d_previous, t_previous_within_solve]
;

s.t. maxShutdown {p in process_online, (d, t) in dt} :
  + (if p in process_online_linear then v_shutdown_linear[p, d, t])
  + (if p in process_online_integer then v_shutdown_integer[p, d, t])
  <=
  + p_entity_all_existing[p, d] / p_entity_unitsize[p]
  + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest]
  - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
;

#s.t. minimum_downtime {p in process_online, t : p_process[u,'min_downtime'] >= step_duration[t]} :
#  + v_online_linear[p, d, t]
#  <=
#  + p_entity_all_existing[p, d] / p_entity_unitsize[p]
#  + sum {(p, d_invest, d) in edd_invest} [p, d_invest]
#   - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest]
#  - sum{(d, t_) in dt : t_ > t && t_ <= t + p_process[u,'min_downtime'] / time_period_duration} (
#      + v_startup_linear[g, n, u, t_]
#	)
#;

# Minimum operational time
#s.t. minimum_uptime {(g, n, u, t) in gnut : u in unit_online && p_unittype[u,'min_uptime_h'] >= time_period_duration / 60 && t >= p_unittype[u,'min_uptime_h'] * 60 #/ time_period_duration} :
#  + v_online[g, n, u, t]
#  >=
#  + sum{t_ in time_in_use : t_ > t - 1 - p_unittype[u,'min_uptime_h'] * 60 / time_period_duration && t_ < t} (
#      + v_startup_linear[g, n, u, t_]
#	)
#;

s.t. ramp_up_variable {(p, source, sink) in process_source_sink_ramp, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} :
  + v_ramp[p, source, sink, d, t]
  =
  + v_flow[p, source, sink, d, t]  * step_duration[d, t]
  - v_flow[p, source, sink, d, t_previous] * step_duration[d, t]
;

s.t. ramp_source_up_constraint {(p, source, sink, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in process_source_sink_dtttdt_ramp_limit_source_up} :
  + v_ramp[p, source, sink, d, t] * p_entity_unitsize[p]
  + sum {r in reserve : (p, r, 'up', source) in process_reserve_upDown_node_active} 
         (v_reserve[p, r, 'up', source, d, t] * p_entity_unitsize[p] / step_duration[d, t])
  <=
  + p_process_source[p, source, 'ramp_speed_up']
    * 60 * step_duration[d, t]
	* p_process_source_coefficient[p, source]
    * ( + p_entity_all_existing[p, d]
	    + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	  )
  + ( if p in process_online_linear then v_startup_linear[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can startup despite ramp limits.
  + ( if p in process_online_integer then v_startup_integer[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can startup despite ramp limits.
;

s.t. ramp_sink_up_constraint {(p, source, sink, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in process_source_sink_dtttdt_ramp_limit_sink_up} :
  + v_ramp[p, source, sink, d, t] * p_entity_unitsize[p]
  + sum {r in reserve : (p, r, 'up', sink) in process_reserve_upDown_node_active} 
         (v_reserve[p, r, 'up', sink, d, t] * p_entity_unitsize[p] / step_duration[d, t])
  <=
  + p_process_sink[p, sink, 'ramp_speed_up']
    * 60 * step_duration[d, t]
	* p_process_sink_coefficient[p, sink]
    * ( + p_entity_all_existing[p, d]
	    + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	  )
  + ( if p in process_online_linear then v_startup_linear[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can startup despite ramp limits.
  + ( if p in process_online_integer then v_startup_integer[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can startup despite ramp limits.
;

s.t. ramp_source_down_constraint {(p, source, sink, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in process_source_sink_dtttdt_ramp_limit_source_down} :
  + v_ramp[p, source, sink, d, t] * p_entity_unitsize[p]
  + sum {r in reserve : (p, r, 'down', source) in process_reserve_upDown_node_active} 
         (v_reserve[p, r, 'down', source, d, t] * p_entity_unitsize[p] / step_duration[d, t])
  >=
  - p_process_sink[p, source, 'ramp_speed_down']
    * 60 * step_duration[d, t]
	* p_process_source_coefficient[p, source]
    * ( + p_entity_all_existing[p, d]
	    + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	  )
  - ( if p in process_online_linear then v_shutdown_linear[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can shutdown despite ramp limits.
  - ( if p in process_online_integer then v_shutdown_integer[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can shutdown despite ramp limits.
;

s.t. ramp_sink_down_constraint {(p, source, sink, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in process_source_sink_dtttdt_ramp_limit_sink_down} :
  + v_ramp[p, source, sink, d, t] * p_entity_unitsize[p]
  + sum {r in reserve : (p, r, 'down', sink) in process_reserve_upDown_node_active} 
         (v_reserve[p, r, 'down', sink, d, t] * p_entity_unitsize[p] / step_duration[d, t])
  >=
  - p_process_sink[p, sink, 'ramp_speed_down']
    * 60 * step_duration[d, t]
	* p_process_sink_coefficient[p, sink]
    * ( + p_entity_all_existing[p, d]
	    + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
        - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	  )
  - ( if p in process_online_linear then v_shutdown_linear[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can shutdown despite ramp limits.
  - ( if p in process_online_integer then v_shutdown_integer[p, d, t] * p_entity_unitsize[p] )  # To make sure that units can shutdown despite ramp limits.
;

s.t. reserve_process_upward{(p, r, 'up', n, d, t) in prundt} :
  + v_reserve[p, r, 'up', n, d, t] * p_entity_unitsize[p]
  <=
  ( if p in process_online then
      + ( + (if p in process_online_linear then v_online_linear[p, d, t])
	      + (if p in process_online_integer then v_online_integer[p, d, t])
		)
	    * p_process_reserve_upDown_node[p, r, 'up', n, 'max_share']
		* p_entity_unitsize[p]
    else
      + p_process_reserve_upDown_node[p, r, 'up', n, 'max_share'] 
        * (
            + p_entity_all_existing[p, d]
            + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
            - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
          )
    	* ( if (sum{(p, prof, 'upper_limit') in process__profile__profile_method} 1) then
	          ( + sum{(p, prof, 'upper_limit') in process__profile__profile_method} pdtProfile[prof, d, t] )
	        else 1
	      )
  )
;

s.t. reserve_process_downward{(p, r, 'down', n, d, t) in prundt} :
  + v_reserve[p, r, 'down', n, d, t] * p_entity_unitsize[p]
  <=
  + p_process_reserve_upDown_node[p, r, 'down', n, 'max_share']
    * ( + sum{(p, source, n) in process_source_sink} v_flow[p, source, n, d, t] * p_entity_unitsize[p]
        - ( + p_entity_all_existing[p, d]
            + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
            - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
          ) * ( if (sum{(p, prof, 'lower_limit') in process__profile__profile_method} 1) then
	              ( + sum{(p, prof, 'lower_limit') in process__profile__profile_method} pdtProfile[prof, d, t] )
	          )
	  )    
;

s.t. maxInvestGroup_entity_period {(g, d) in gd_invest_period} :
  + sum{(g, e) in group_entity : (e, d) in ed_invest} v_invest[e, d] * p_entity_unitsize[e]
  <=
  + pdGroup[g, 'invest_max_period', d]
;

s.t. maxDivestGroup_entity_period {(g, d) in gd_divest_period} :
  + sum{(g, e) in group_entity : (e, d) in ed_divest} v_divest[e, d] * p_entity_unitsize[e]
  <=
  + pdGroup[g, 'retire_max_period', d]
;

s.t. minInvestGroup_entity_period {(g, d) in gd_invest_period} :
  + sum{(g, e) in group_entity : (e, d) in ed_invest} v_invest[e, d] * p_entity_unitsize[e]
  >=
  + pdGroup[g, 'invest_min_period', d]
;

s.t. minDivestGroup_entity_period {(g, d) in gd_divest_period} :
  + sum{(g, e) in group_entity : (e, d) in ed_divest} v_divest[e, d] * p_entity_unitsize[e]
  >=
  + pdGroup[g, 'retire_min_period', d]
;

s.t. maxInvestGroup_entity_total {g in g_invest_total, d in period} :
  + sum{(g, e) in group_entity, d_invest in period : (e, d_invest, d) in edd_invest} v_invest[e, d_invest] * p_entity_unitsize[e]
  + sum{(g, e) in group_entity} p_entity_previously_invested_capacity[e, d]
  <=
  + p_group[g, 'invest_max_total']
;

s.t. maxDivestGroup_entity_total {g in g_divest_total} :
  + sum{(g, e) in group_entity, d in period : e in entityDivest} v_divest[e, d] * p_entity_unitsize[e]
  + sum{(g, e) in group_entity : e in entityDivest} (if not p_model['solveFirst'] then p_entity_divested[e])
  <=
  + p_group[g, 'retire_max_total']
;

s.t. minInvestGroup_entity_total {g in g_invest_total, d in period} :
  + sum{(g, e) in group_entity, d_invest in period : (e, d_invest, d) in edd_invest} v_invest[e, d_invest] * p_entity_unitsize[e]
  + sum{(g, e) in group_entity} p_entity_previously_invested_capacity[e, d]
  >=
  + p_group[g, 'invest_min_total']
;

s.t. minDivestGroup_entity_total {g in g_divest_total} :
  + sum{(g, e) in group_entity, d in period : e in entityDivest} v_divest[e, d] * p_entity_unitsize[e]
  + sum{(g, e) in group_entity : e in entityDivest} (if not p_model['solveFirst'] then p_entity_divested[e])
  >=
  + p_group[g, 'retire_min_total']
;

s.t. maxInvest_entity_period {(e, d) in ed_invest_period} :  # Covers both processes and nodes
  + v_invest[e, d] * p_entity_unitsize[e] 
  <= 
  + ed_invest_max_period[e, d]
;

s.t. maxDivest_entity_period {(e, d) in ed_divest_period} :  # Covers both processes and nodes
  + v_divest[e, d] * p_entity_unitsize[e] 
  <= 
  + ed_divest_max_period[e, d]
;

s.t. minInvest_entity_period {(e, d)  in ed_invest_period} :  # Covers both processes and nodes
  + v_invest[e, d] * p_entity_unitsize[e] 
  >= 
  + ed_invest_min_period[e, d]
;

s.t. minDivest_entity_period {(e, d)  in ed_divest_period} :  # Covers both processes and nodes
  + v_divest[e, d] * p_entity_unitsize[e] 
  >= 
  + ed_divest_min_period[e, d]
;

s.t. maxInvest_entity_total {e in e_invest_total, d in period} :  # Covers both processes and nodes
  + sum{(e, d_invest, d) in edd_invest} v_invest[e, d_invest] * p_entity_unitsize[e] 
  + p_entity_previously_invested_capacity[e, d]
  <= 
  + e_invest_max_total[e]
;

s.t. maxDivest_entity_total {e in e_divest_total} :  # Covers both processes and nodes
  + sum{(e, d) in ed_divest} v_divest[e, d] * p_entity_unitsize[e] 
  + (if not p_model['solveFirst'] then p_entity_divested[e])
  <= 
  + e_divest_max_total[e]
;

s.t. minInvest_entity_total {e in e_invest_total, d in period} :  # Covers both processes and nodes
  + sum{(e, d_invest, d) in edd_invest} v_invest[e, d_invest] * p_entity_unitsize[e] 
  + p_entity_previously_invested_capacity[e, d]
  >= 
  + e_invest_min_total[e]
;

s.t. minDivest_entity_total {e in e_divest_total} :  # Covers both processes and nodes
  + sum{(e, d) in ed_divest} v_divest[e, d] * p_entity_unitsize[e] 
  + (if not p_model['solveFirst'] then p_entity_divested[e])
  >= 
  + e_divest_min_total[e]
;

s.t. maxCumulative_capacity {(e, d) in ed_invest_cumulative} :
  + p_entity_all_existing[e, d]
  + sum{(e, d_invest, d) in edd_invest} v_invest[e, d_invest] * p_entity_unitsize[e]
  - (if (e, d) in ed_divest then v_divest[e, d] * p_entity_unitsize[e])
  <=
  + ed_cumulative_max_capacity[e, d]
;

s.t. minCumulative_capacity {(e, d) in ed_invest_cumulative : ed_cumulative_min_capacity[e, d]} :
  + p_entity_all_existing[e, d]
  + sum{(e, d_invest, d) in edd_invest} v_invest[e, d_invest] * p_entity_unitsize[e]
  - (if (e, d) in ed_divest then v_divest[e, d] * p_entity_unitsize[e])
  >=
  + ed_cumulative_min_capacity[e, d]
;

s.t. maxCumulative_flow_solve {g in group : p_group[g, 'max_cumulative_flow']} :
  + sum{(g, p, n) in group_process_node, (d, t) in dt} (
      # n is sink
      + sum {(p, source, n) in process_source_sink} (
          + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
	    )  
      # n is source
      - sum {(p, n, sink) in process_source_sink_eff } ( 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	           * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
		      + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
				  + (if p in process_online_integer then v_online_integer[p, d, t])
				)
		    	* pdtProcess_section[p, d, t]
			    * p_entity_unitsize[p]
		    )
        )		
      - sum {(p, n, sink) in process_source_sink_noEff } (
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
		)
	) * step_duration[d, t]
	<=
  + p_group[g, 'max_cumulative_flow'] 
      * hours_in_solve
;

s.t. minCumulative_flow_solve {g in group : p_group[g, 'min_cumulative_flow']} :
  + sum{(g, p, n) in group_process_node, (d, t) in dt} (
      # n is sink
      + sum {(p, source, n) in process_source_sink} (
          + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
	    )  
      # n is source
      - sum {(p, n, sink) in process_source_sink_eff } ( 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	           * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
		      + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
				  + (if p in process_online_integer then v_online_integer[p, d, t])
				)
		    	* pdtProcess_section[p, d, t]
			    * p_entity_unitsize[p]
		    )
        )		
      - sum {(p, n, sink) in process_source_sink_noEff } (
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
		)  
	) * step_duration[d, t]
	>=
  + p_group[g, 'min_cumulative_flow'] 
      * hours_in_solve
;

s.t. maxCumulative_flow_period {g in group, d in period : pdGroup[g, 'max_cumulative_flow', d]} :
  + sum{(g, p, n) in group_process_node, (d, t) in dt} (
      # n is sink
      + sum {(p, source, n) in process_source_sink} (
          + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
	    )  
      # n is source
      - sum {(p, n, sink) in process_source_sink_eff } ( 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	           * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
		    	* pdtProcess_section[p, d, t]
			    * p_entity_unitsize[p]
		    )
        )		
      - sum {(p, n, sink) in process_source_sink_noEff } (
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
		)
	)  * step_duration[d, t]
	<=
  + pdGroup[g, 'max_cumulative_flow', d] 
      * hours_in_period[d]
;

s.t. minCumulative_flow_period {g in group, d in period : pdGroup[g, 'min_cumulative_flow', d]} :
  + sum{(g, p, n) in group_process_node, (d, t) in dt} (
      # n is sink
      + sum {(p, source, n) in process_source_sink} (
          + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
	    )  
      # n is source
      - sum {(p, n, sink) in process_source_sink_eff } ( 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	           * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
		        * pdtProcess_section[p, d, t]
			   	* p_entity_unitsize[p]
		    )
        )		
      - sum {(p, n, sink) in process_source_sink_noEff } (
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
		)
	) * step_duration[d, t]
	>=
  + pdGroup[g, 'min_cumulative_flow', d] 
      * hours_in_period[d]
;

s.t. maxInstant_flow {(g, d, t) in gdt_maxInstantFlow} :
  + sum{(g, p, n) in group_process_node} (
      # n is sink
      + sum {(p, source, n) in process_source_sink} (
          + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
	    )  
      # n is source
      - sum {(p, n, sink) in process_source_sink_eff } ( 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	           * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
		    	* pdtProcess_section[p, d, t]
			    * p_entity_unitsize[p]
		    )
        )		
      - sum {(p, n, sink) in process_source_sink_noEff } 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	)
	<=
  + pdtGroup[g, 'max_instant_flow', d, t] 
;

s.t. minInstant_flow {(g, d, t) in gdt_minInstantFlow} :
  + sum{(g, p, n) in group_process_node} (
      # n is sink
      + sum {(p, source, n) in process_source_sink} (
          + v_flow[p, source, n, d, t] * p_entity_unitsize[p]
	    )  
      # n is source
      - sum {(p, n, sink) in process_source_sink_eff } ( 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	           * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
	    	    * pdtProcess_section[p, d, t]
		    	* p_entity_unitsize[p]
		    )
        )		
      - sum {(p, n, sink) in process_source_sink_noEff } 
          + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
	)
	>=
  + pdtGroup[g, 'min_instant_flow', d, t] 
;

s.t. inertia_constraint {g in groupInertia, (d, t) in dt} :
  + sum {(p, source, sink) in process_source_sink : (p, source) in process_source && (g, source) in group_node && p_process_source[p, source, 'inertia_constant']} 
    ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
      + (if p in process_online_integer then v_online_integer[p, d, t]) 
	  + (if p not in process_online then v_flow[p, source, sink, d, t])
	) * p_process_source[p, source, 'inertia_constant'] * p_entity_unitsize[p]
  + sum {(p, source, sink) in process_source_sink : (p, sink) in process_sink && (g, sink) in group_node && p_process_sink[p, sink, 'inertia_constant']} 
    ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
      + (if p in process_online_integer then v_online_integer[p, d, t]) 
	  + (if p not in process_online then v_flow[p, source, sink, d, t])
    ) * p_process_sink[p, sink, 'inertia_constant'] * p_entity_unitsize[p]
  + vq_inertia[g, d, t] * pdGroup[g, 'inertia_limit', d]
  >=
  + pdGroup[g, 'inertia_limit', d]
;

s.t. co2_max_period{g in group_co2_max_period, d in period_in_use} :
  + sum{(g, c, n, d) in group_commodity_node_period_co2_period }
    ( 
      + p_commodity[c, 'co2_content']  
        * (
            # CO2 increases 
            + sum {(p, n, sink) in process_source_sink_noEff, (d, t) in dt } 
              ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p] * step_duration[d, t] )
            + sum {(p, n, sink) in process_source_sink_eff, (d, t) in dt } 
              ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p] * step_duration[d, t]
                  * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
                  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
                + ( if (p, 'min_load_efficiency') in process__ct_method then 
                    + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
                        + (if p in process_online_integer then v_online_integer[p, d, t])
                      )
                      * pdtProcess_section[p, d, t]
                      * p_entity_unitsize[p]
                  )	  
              ) 
            # CO2 removals
            - sum {(p, source, n) in process_source_sink, (d, t) in dt } 
              ( + v_flow[p, source, n, d, t] * p_entity_unitsize[p] * step_duration[d, t] )  
          ) / complete_period_share_of_year[d]
    )
  <=
  + pdGroup[g, 'co2_max_period', d]
;

s.t. co2_max_total{g in group_co2_max_total} :
  + sum{(g, c, n) in group_commodity_node_period_co2_total }
    ( 
      + p_commodity[c, 'co2_content']  
        * (
            # CO2 increases 
            + sum {(p, n, sink) in process_source_sink_noEff, (d, t) in dt } 
              ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p] * step_duration[d, t] )
            + sum {(p, n, sink) in process_source_sink_eff, (d, t) in dt } 
              ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p] * step_duration[d, t]
                  * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
                  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] / p_process_source_coefficient[p, n]) else 1)
                + ( if (p, 'min_load_efficiency') in process__ct_method then 
                    + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
                        + (if p in process_online_integer then v_online_integer[p, d, t])
                      )
                      * pdtProcess_section[p, d, t]
                      * p_entity_unitsize[p]
				  )
              )	  
          # CO2 removals
            - sum {(p, source, n) in process_source_sink, (d, t) in dt } 
              ( + v_flow[p, source, n, d, t] * p_entity_unitsize[p] * step_duration[d, t]
              )  
          )
    )
  <=
  + p_group[g, 'co2_max_total']
;

s.t. non_sync_constraint{g in groupNonSync, (d, t) in dt} :
  + sum {(p, source, sink) in process_source_sink : (p, sink) in process__sink_nonSync && (g, sink) in group_node && (p,g) not in process__group_inside_group_nonSync}
    ( + v_flow[p, source, sink, d, t] 
	    * p_entity_unitsize[p]  
		* step_duration[d, t] )
  + sum {(g, n) in group_node} p_positive_inflow[n,d,t]
  - vq_non_synchronous[g, d, t] * group_capacity_for_scaling[g, d]
  <=
  ( + sum {(p, source, sink) in process_source_sink_noEff : (g, source) in group_node  && (p,g) not in process__group_inside_group_nonSync} 
      ( + v_flow[p, source, sink, d, t] 
		  * p_entity_unitsize[p] 
	  ) * step_duration[d, t]
    + sum {(p, source, sink) in process_source_sink_eff: (g, source) in group_node}
      ( + v_flow[p, source, sink, d, t]
	      * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
	      * (if p in process_unit then 1 / ( p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, source]) else 1)
  	    + ( if (p, 'min_load_efficiency') in process__ct_method then 
	        + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
	            + (if p in process_online_integer then v_online_integer[p, d, t])
	          )
		      * pdtProcess_section[p, d, t]
	      )
        -(if (p,g) in process__group_inside_group_nonSync then v_flow[p, source, sink, d, t] else 0)
	  )	* p_entity_unitsize[p]
		* step_duration[d, t]
    + sum {(g, n) in group_node} -p_negative_inflow[n,d,t]
  ) * pdGroup[g, 'non_synchronous_limit', d]
;

s.t. capacityMargin {g in groupCapacityMargin, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt : d in period_invest} :
  # profile limited units producing to a node in the group (based on available capacity)
  + sum {(p, source, sink, f, m) in process__source__sink__profile__profile_method 
         : m = 'upper_limit' || m = 'fixed'
           && (p, sink) in process_sink
		   && (g, sink) in group_node
		   && p in process_unit
		} 
    ( + pdtProfile[f, d, t]
        * ( + p_entity_all_existing[p, d]
            + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
            - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
	      )
    )
  # capacity limited units producing to a node in the group (based on available capacity)
  + sum {(p, source, sink) in process_source_sink 
         : (p, sink) in process_sink 
	       && sum {(p, source, sink, f, m) in process__source__sink__profile__profile_method : m = 'upper_limit' || m = 'fixed'} 1 = 0
		   && (p, sink) in process_sink
  		   && (g, sink) in group_node 
		   && p in process_unit
		} 
	(
      + ( + p_entity_all_existing[p, d]
          + sum {(p, d_invest, d) in edd_invest} v_invest[p, d_invest] * p_entity_unitsize[p]
          - sum {(p, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[p, d_divest] * p_entity_unitsize[p]
        )
	)
  # profile or capacity limited units consuming from a node in the group (as they consume in any given time step)
  - sum {(p, source, sink) in process_source_sink 
         : (p, source) in process_source
		   && (g, source) in group_node
		   && p in process_unit
		} 
    ( + if (p, source, sink) in process_source_sink_eff then 
        ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
	          * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
		      * 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, source])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
			    * pdtProcess_section[p, d, t]
			    * p_entity_unitsize[p]
	  	    )
	    ) * step_duration[d, t]
	  + if (p, source, sink) in process_source_sink_noEff then
        ( + v_flow[p, source, sink, d, t] * p_entity_unitsize[p]
        ) * step_duration[d, t]
	)
  + vq_capacity_margin[g, d] * group_capacity_for_scaling[g, d]
  >=
  + sum {(g, n) in group_node} 
    ( - (if (n, 'no_inflow') not in node__inflow_method then pdtNodeInflow[n, d, t])
      + (if n in nodeState && (n, 'bind_forward_only') in node__storage_binding_method && not ((d, t) in period__time_first && d in period_first_of_solve) then (v_state[n, d, t] -  v_state[n, d_previous, t_previous_within_solve]) * p_entity_unitsize[n])
      + (if n in nodeState && (n, 'bind_within_solve') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d_previous, t_previous_within_solve]) * p_entity_unitsize[n])
      + (if n in nodeState && (n, 'bind_within_period') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d, t_previous]) * p_entity_unitsize[n])
      + (if n in nodeState && (n, 'bind_within_timeblock') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d, t_previous_within_block]) * p_entity_unitsize[n])
      + (if n in nodeState && (d, t) in period__time_first && d in period_first_of_solve && not p_nested_model['solveFirst'] then (v_state[n,d,t] * p_entity_unitsize[n] - p_roll_continue_state[n])) 
      + (if n in nodeState && (n, 'bind_forward_only') in node__storage_binding_method && (d, t) in period__time_first && d in period_first_of_solve && p_nested_model['solveFirst'] 
      && ((n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)
      then (+ v_state[n,d,t] * p_entity_unitsize[n] 
            - p_node[n,'storage_state_start'] * 
            (+ p_entity_all_existing[n, d]
            + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
            - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
      )))
  )
  + pdGroup[g, 'capacity_margin', d]
;

s.t. group_loss_share_constraint{(g,n) in group_node, (d,t) in dt: g in group_loss_share && n in nodeBalance}:
  + vq_state_up[n,d,t]  * node_capacity_for_scaling[n, d] 
  =  
  + p_state_slack_share[g,n,d,t] * vq_state_up_group[g,d,t] * group_capacity_for_scaling[g,d];

s.t. non_anticipativity_storage_use{n in nodeState, (d,b) in period__branch, (d,t) in dt_non_anticipativity:
      d != b && b in period_in_use && exists{(g,n) in group_node: g in groupStochastic} 1}:
        # n is sink
        + sum {(p, source, n) in process_source_sink} (
            + v_flow[p, source, n, d, t] * p_entity_unitsize[p] * step_duration[d, t]
        )  
        # n is source
        - sum {(p, n, sink) in process_source_sink_eff } ( 
            + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
              * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
            * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
            + (if (p, 'min_load_efficiency') in process__ct_method then 
              + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
                  + (if p in process_online_integer then v_online_integer[p, d, t])
              )
                * pdtProcess_section[p, d, t]
              * p_entity_unitsize[p]
          )
          ) * step_duration[d, t]		
        - sum {(p, n, sink) in process_source_sink_noEff} 
          ( + v_flow[p, n, sink, d, t] * p_entity_unitsize[p]
          ) * step_duration[d, t]

        =
          # n is sink
        + sum {(p, source, n) in process_source_sink} (
            + v_flow[p, source, n, b, t] * p_entity_unitsize[p] * step_duration[b, t]
        )  
        # n is source
        - sum {(p, n, sink) in process_source_sink_eff } ( 
            + v_flow[p, n, sink, b, t] * p_entity_unitsize[p]
              * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, b, t] else 1 / pdtProcess[p, 'efficiency', b, t])
            * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink] * p_process_source_coefficient[p, n]) else 1)
            + (if (p, 'min_load_efficiency') in process__ct_method then 
              + ( + (if p in process_online_linear then v_online_linear[p, b, t]) 
                  + (if p in process_online_integer then v_online_integer[p, b, t])
              )
                * pdtProcess_section[p, b, t]
              * p_entity_unitsize[p]
          )
          ) * step_duration[b, t]		
        - sum {(p, n, sink) in process_source_sink_noEff} 
          ( + v_flow[p, n, sink, b, t] * p_entity_unitsize[p]
          ) * step_duration[b, t]
        ;

s.t. non_anticipativity_online_integer{p in process_online_integer, (d,b) in period__branch, (d,t) in dt_non_anticipativity: b in period_in_use}:
  + v_online_integer[p,d,t] 
  = 
  + v_online_integer[p,b,t] 
;
s.t. non_anticipativity_online_linear{p in process_online_linear, (d,b) in period__branch, (d,t) in dt_non_anticipativity: b in period_in_use}:
  + v_online_linear[p,d,t] 
  = 
  + v_online_linear[p,b,t] 
;
s.t. non_anticipativity_reserve{(p, r, ud, n) in process_reserve_upDown_node_active, (d,b) in period__branch, (d,t) in dt_non_anticipativity: sum{(r, ud, g) in reserve__upDown__group} 1 && b in period_in_use}: 
  + v_reserve[p, r, ud, n, d, t]
  =
  + v_reserve[p, r, ud, n, b, t]
;
param rest := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect;
display rest;

solve;

param w_solve := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest;
display w_solve;

param hours_in_realized_period{d in d_realized_period} := sum {(d, t) in dt_realize_dispatch} (step_duration[d, t]);
param realized_period_share_of_year{d in d_realized_period}:= hours_in_realized_period[d] / 8760;

param entity_all_capacity{e in entity, d in period} :=
  + p_entity_all_existing[e, d]
  + sum {(e, d_invest, d) in edd_invest} v_invest[e, d_invest].val * p_entity_unitsize[e]
  - sum {(e, d_divest) in ed_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[e, d_divest].val * p_entity_unitsize[e]
;

param r_process_Online__dt{p in process_online, (d, t) in dt} :=
  + (if p in process_online_linear then v_online_linear[p, d, t].val)
  + (if p in process_online_integer then v_online_integer[p, d, t].val);

param r_process__source__sink_Flow__dt{(p, source, sink) in process_source_sink_alwaysProcess, (d, t) in dt} :=
  + sum {(p, m) in process_method : m in method_1var_per_way}
    ( + sum {(p, source, sink2) in process_source_toSink} 
        ( + v_flow[p, source, sink2, d, t].val * p_entity_unitsize[p]
	          * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
	  		  * (if p in process_unit then 1 / (p_process_sink_coefficient[p, sink2] * p_process_source_coefficient[p, source]) else 1)
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + r_process_Online__dt[p, d, t]
			    * pdtProcess_section[p, d, t] * p_entity_unitsize[p])
	    )
      + sum {(p, source2, sink) in process_source_toSink} 
          + v_flow[p, source2, sink, d, t].val * p_entity_unitsize[p]
      + sum {(p, source, sink2) in process_sink_toSource} 
        ( + v_flow[p, source, sink2, d, t].val * p_entity_unitsize[p]
	          * (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
          + (if (p, 'min_load_efficiency') in process__ct_method then 
			  + ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
			      + (if p in process_online_integer then v_online_integer[p, d, t])
				)
	            * pdtProcess_section[p, d, t] * p_entity_unitsize[p])
	    )
      + sum {(p, source2, sink) in process_sink_toSource} 
          + v_flow[p, source2, sink, d, t].val * p_entity_unitsize[p]
      + (if (p, source, sink) in process__profileProcess__toSink then 
	      + v_flow[p, source, sink, d, t].val * p_entity_unitsize[p])
      + (if (p, source, sink) in process__source__toProfileProcess then 
	      + v_flow[p, source, sink, d, t].val * p_entity_unitsize[p])
	  + (if (p, source, sink) in process_process_toSink then
	      + v_flow[p, source, sink, d, t].val * p_entity_unitsize[p])
	  + (if (p, source, sink) in process_source_toProcess then
	      + v_flow[p, source, sink, d, t].val * p_entity_unitsize[p])
   )
  + sum {(p, m) in process_method : m in method_nvar} (
      + v_flow[p, source, sink, d, t].val * p_entity_unitsize[p]
	)
  + sum {(p, source, sink2) in process_source_sink : (p, 'method_2way_1var_off') in process_method && (p, source, sink) in process_source_toProcess_direct} ( 
      + v_flow[p, source, sink2, d, t].val * p_entity_unitsize[p]
	)
  + sum {(p, source2, sink) in process_source_sink : (p, 'method_2way_1var_off') in process_method && (p, source, sink) in process_process_toSink_direct} (
      + v_flow[p, source2, sink, d, t].val * p_entity_unitsize[p]
    )
;
param r_process__source__sink_Flow__d{(p, source, sink) in process_source_sink_alwaysProcess, d in d_realized_period}:=
  + sum{(d, t) in dt_realize_dispatch} r_process__source__sink_Flow__dt[p, source, sink, d, t];

param r_process_source_sink_ramp_dtt{(p, source, sink) in process_source_sink_alwaysProcess, (d, t, t_previous) in dtt} :=
  + r_process__source__sink_Flow__dt[p, source, sink, d, t]
  - r_process__source__sink_Flow__dt[p, source, sink, d, t_previous]
;

param r_node_ramp_dtt{n in nodeBalance, (d, t, t_previous) in dtt} :=
  + sum {(p, n, sink) in process_source_sink_alwaysProcess} r_process_source_sink_ramp_dtt[p, n, sink, d, t, t_previous]
  + sum {(p, source, n) in process_source_sink_alwaysProcess} -r_process_source_sink_ramp_dtt[p, source, n, d, t, t_previous]
;

param r_connection_dt{c in process_connection, (d, t) in dt} :=
  + sum{(c, c, n) in process_source_sink_alwaysProcess : (c, n) in process_sink} r_process__source__sink_Flow__dt[c, c, n, d, t]
  - sum{(c, c, n) in process_source_sink_alwaysProcess : (c, n) in process_source} r_process__source__sink_Flow__dt[c, c, n, d, t]
;
param r_connection_to_left_node__dt{c in process_connection, (d, t) in dt: 'output_connection_flow_separate' in enable_optional_outputs} :=
  + sum{(c, c, n) in process_source_sink_alwaysProcess : (c, n) in process_source}
      r_process__source__sink_Flow__dt[c, c, n, d, t]
;
param r_connection_to_right_node__dt{c in process_connection, (d, t) in dt: 'output_connection_flow_separate' in enable_optional_outputs} :=
  + sum{(c, c, n) in process_source_sink_alwaysProcess : (c, n) in process_sink}
      r_process__source__sink_Flow__dt[c, c, n, d, t]
;
param r_group_output__connection_Not_in_aggregate__dt{(g, c) in group_output__connection_Not_in_aggregate, (d, t) in dt} :=
  + sum{(g, c, c, n) in group_output__process__connection__to_node_Not_in_aggregate}
      + r_process__source__sink_Flow__dt[c, c, n, d, t]
  + sum{(g, c, n, c) in group_output__process__node__to_connection_Not_in_aggregate}
      - r_process__source__sink_Flow__dt[c, n, c, d, t]
;
param r_group_output__connection_Not_in_aggregate__d{(g, c) in group_output__connection_Not_in_aggregate, d in d_realized_period}:=
  + sum{(d, t) in dt_realize_dispatch} r_group_output__connection_Not_in_aggregate__dt[g, c, d, t];

param r_process_source_sink_flow_d{(p, source, sink) in process_source_sink_alwaysProcess, d in d_realized_period} :=
  + sum {(d, t) in dt_realize_dispatch} ( r_process__source__sink_Flow__dt [p, source, sink, d, t] * step_duration[d, t] )
;

param r_process_source_flow_d{(p, source) in process_source, d in d_realized_period} := 
  + sum {(p, source, sink) in process_source_sink_alwaysProcess} r_process_source_sink_flow_d[p, source, sink, d]
;
param r_process_sink_flow_d{(p, sink) in process_sink, d in d_realized_period} := 
  + sum {(p, source, sink) in process_source_sink_alwaysProcess} r_process_source_sink_flow_d[p, source, sink, d]
;

param r_connection_d{c in process_connection, d in d_realized_period} :=
  + sum {(d, t) in dt_realize_dispatch} r_connection_dt[c, d, t] * step_duration[d, t]
;

param r_connection_to_left_node__d{c in process_connection, d in d_realized_period: 'output_connection_flow_separate' in enable_optional_outputs} :=
  + sum {(d, t) in dt_realize_dispatch} r_connection_to_left_node__dt[c, d, t] * step_duration[d, t]
;

param r_connection_to_right_node__d{c in process_connection, d in d_realized_period: 'output_connection_flow_separate' in enable_optional_outputs} :=
  + sum {(d, t) in dt_realize_dispatch} r_connection_to_right_node__dt[c, d, t] * step_duration[d, t]
;

param r_nodeState_change_dt{n in nodeState, (d, t) in dt_realize_dispatch} := sum {(d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt} (
      + (if (n, 'bind_forward_only') in node__storage_binding_method && not ((d, t) in period__time_first && d in period_first_of_solve) then (v_state[n, d, t] -  v_state[n, d_previous, t_previous_within_solve]) * p_entity_unitsize[n])
      + (if (n, 'bind_within_solve') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d_previous, t_previous_within_solve]) * p_entity_unitsize[n])
      + (if (n, 'bind_within_period') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d, t_previous]) * p_entity_unitsize[n])
      + (if (n, 'bind_within_timeblock') in node__storage_binding_method && (n, 'fix_start_end') not in node__storage_start_end_method then (v_state[n, d, t] -  v_state[n, d, t_previous_within_block]) * p_entity_unitsize[n])
      + (if (d, t) in period__time_first && d in period_first_of_solve && not p_nested_model['solveFirst'] then (v_state[n,d,t] * p_entity_unitsize[n] - p_roll_continue_state[n])) 
      + (if (n, 'bind_forward_only') in node__storage_binding_method && (d, t) in period__time_first && d in period_first_of_solve && p_nested_model['solveFirst'] 
      && ((n, 'fix_start') in node__storage_start_end_method || (n, 'fix_start_end') in node__storage_start_end_method)
      then (+ v_state[n,d,t] * p_entity_unitsize[n] 
            - p_node[n,'storage_state_start'] * 
            (+ p_entity_all_existing[n, d]
            + sum {(n, d_invest, d) in edd_invest} v_invest[n, d_invest] * p_entity_unitsize[n]
            - sum {(n, d_divest) in pd_divest : p_years_d[d_divest] <= p_years_d[d]} v_divest[n, d_divest] * p_entity_unitsize[n]
      )))
);
param r_nodeState_change_d{n in nodeState, d in d_realized_period} := sum {(d, t) in dt_realize_dispatch} r_nodeState_change_dt[n, d, t];
param r_selfDischargeLoss_dt{n in nodeSelfDischarge, (d, t) in dt_realize_dispatch} := v_state[n, d, t] * pdtNode[n, 'self_discharge_loss', d, t] * p_entity_unitsize[n];
param r_selfDischargeLoss_d{n in nodeSelfDischarge, d in d_realized_period} := sum{(d, t) in dt_realize_dispatch} r_selfDischargeLoss_dt[n, d, t] * step_duration[d, t];

param r_cost_commodity_dt{(c, n) in commodity_node, (d, t) in dt} := 
  + step_duration[d, t] 
      * pdtCommodity[c, 'price', d, t] 
      * ( + sum{(p, n, sink) in process_source_sink_alwaysProcess}
              + r_process__source__sink_Flow__dt[p, n, sink, d, t]
		  - sum{(p, source, n) in process_source_sink_alwaysProcess}	  
              + r_process__source__sink_Flow__dt[p, source, n, d, t]
	    )
;

param r_process_commodity_d{(p, c, n) in process__commodity__node, d in d_realized_period} :=
 + sum{(p, n, sink) in process_source_sink_alwaysProcess}
      + r_process_source_sink_flow_d[p, n, sink, d]
 - sum{(p, source, n) in process_source_sink_alwaysProcess}	  
      + r_process_source_sink_flow_d[p, source, n, d]
;

param r_process_emissions_co2_dt{(p, c, n) in process__commodity__node_co2, (d, t) in dt} := 
  + step_duration[d, t]
      * p_commodity[c, 'co2_content'] 
      * ( + sum{(p, n, sink) in process_source_sink_alwaysProcess}
              + r_process__source__sink_Flow__dt[p, n, sink, d, t]
	      - sum{(p, source, n) in process_source_sink_alwaysProcess}	  
              + r_process__source__sink_Flow__dt[p, source, n, d, t]
        )
;	  

param r_process_emissions_co2_d{(p, c, n) in process__commodity__node_co2, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} ( r_process_emissions_co2_dt[p, c, n, d, t] ) / complete_period_share_of_year[d];

param r_emissions_co2_dt{(c, n) in commodity_node_co2, (d, t) in dt} :=
  + sum{(p, c, n) in process__commodity__node_co2} r_process_emissions_co2_dt[p, c, n, d, t];

param r_emissions_co2_d{(c, n) in commodity_node_co2, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} ( r_emissions_co2_dt[c, n, d, t] ) / complete_period_share_of_year[d];

param r_cost_co2_dt{(g, c, n, d, t) in gcndt_co2_price} := 
  + r_emissions_co2_dt[c, n, d, t] 
    * pdtGroup[g, 'co2_price', d, t]
;	  

param r_cost_process_other_operational_cost_dt{p in process, (d, t) in dt} :=
  + step_duration[d, t]
      * sum{(p, source, sink) in process_source_sink_alwaysProcess}
          + pdtProcess__source__sink__dt_varCost_alwaysProcess[p, source, sink, d, t]
	          * r_process__source__sink_Flow__dt[p, source, sink, d, t]
#	  * ( + sum {(p, source, sink, 'other_operational_cost') in process__source__sink__param_t}
#	        ( + sum{(p, n, sink) in process_source_sink_alwaysProcess : (p, sink) in process_sink}
#  			      + ptProcess_source_sink[p, source, sink, 'other_operational_cost', t]
#		              * r_process__source__sink_Flow__dt[p, n, sink, d, t]
#	          + sum{(p, source, n) in process_source_sink_alwaysProcess : (p, source) in process_source}
#  			      + ptProcess_source_sink[p, source, sink, 'other_operational_cost', t]
#		              * r_process__source__sink_Flow__dt[p, source, n, d, t]
#			)
#		)
;
#param r_cost_process_ramp_cost_dt{p in process, (d, t) in dt :
#  sum {(p, source, sink, m) in process__source__sink__ramp_method : m in ramp_cost_method} 1 } :=
#  + step_duration[d, t]
#	  * sum {(p, source, sink, m) in process__source__sink__ramp_method : m in ramp_cost_method} 
#	      + pProcess_source_sink[p, source, sink, 'ramp_cost']
#              * v_ramp[p, source, sink, d, t].val * p_entity_unitsize[p]
#;
param r_process_startup_dt{p in process, (d, t) in dt : p in process_online} :=
  ( + (if p in process_online_linear then v_startup_linear[p, d, t])
    + (if p in process_online_integer then v_startup_integer[p, d, t])
  );

param r_cost_startup_dt{p in process, (d, t) in dt : p in process_online && pdProcess[p, 'startup_cost', d]} :=
  ( r_process_startup_dt[p, d, t]
    * pdProcess[p, 'startup_cost', d]
	* p_entity_unitsize[p]
  );

param r_costPenalty_nodeState_upDown_dt{n in (nodeBalance union nodeBalancePeriod), ud in upDown, (d, t) in dt} :=
  + (if ud = 'up'   then vq_state_up[n, d, t] * node_capacity_for_scaling[n, d] * pdtNode[n, 'penalty_up', d, t])
  + (if ud = 'down' then vq_state_down[n, d, t] * node_capacity_for_scaling[n, d] * pdtNode[n, 'penalty_down', d, t]) ;

param r_penalty_nodeState_upDown_d{n in (nodeBalance union nodeBalancePeriod), ud in upDown, d in d_realized_period} :=
  + sum {(d, t) in dt_realize_dispatch : ud = 'up'}  vq_state_up[n, d, t] * node_capacity_for_scaling[n, d]
  + sum {(d, t) in dt_realize_dispatch : ud = 'down'}  vq_state_down[n, d, t] * node_capacity_for_scaling[n, d];

param r_costPenalty_inertia_dt{g in groupInertia, (d, t) in dt} :=
  + step_duration[d, t]
      * vq_inertia[g, d, t] * pdGroup[g, 'inertia_limit', d]
	  * pdGroup[g, 'penalty_inertia', d]
;

param r_costPenalty_non_synchronous_dt{g in groupNonSync, (d, t) in dt} :=
  + step_duration[d, t]
      * vq_non_synchronous[g, d, t] * group_capacity_for_scaling[g, d]
	  * pdGroup[g, 'penalty_non_synchronous', d]
;

param r_costPenalty_capacity_margin_d{g in groupCapacityMargin, d in period_invest} :=
  + vq_capacity_margin[g, d] * group_capacity_for_scaling[g, d]
      * pdGroup[g, 'penalty_capacity_margin', d]
	  * p_discount_factor_operations_yearly[d]
;

param r_costPenalty_reserve_upDown_dt{(r, ud, ng) in reserve__upDown__group, (d, t) in dt} :=
  + step_duration[d, t]
      * (
          + vq_reserve[r, ud, ng, d, t] * p_reserve_upDown_group[r, ud, ng, 'penalty_reserve'] * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t]
	    )
;

param r_cost_entity_invest_d{(e, d) in ed_invest} :=
  + v_invest[e, d]
      * p_entity_unitsize[e]
      * ed_entity_annual[e, d]
	  * p_discount_factor_operations_yearly[d]
;

param r_cost_entity_divest_d{(e, d) in ed_divest} :=
  - v_divest[e, d]
      * p_entity_unitsize[e]
      * ed_entity_annual_divest[e, d]
	  * p_discount_factor_operations_yearly[d]
;

param r_cost_entity_existing_fixed{e in entity, d in d_realize_invest : (e, d) not in ed_invest} :=
  + p_entity_all_existing[e, d]
      * ( + if e in process then pdProcess[e, 'fixed_cost', d] else 0 
	      + if e in node then pdNode[e, 'fixed_cost', d] else 0 
		)
	  * 1000
	  * p_discount_factor_operations_yearly[d]
;

param r_costOper_dt{(d, t) in dt} :=
  + sum{(c, n) in commodity_node} r_cost_commodity_dt[c, n, d, t]
  + sum{(g, c, n, d, t) in gcndt_co2_price} r_cost_co2_dt[g, c, n, d, t]
  + sum{p in process} r_cost_process_other_operational_cost_dt[p, d, t]
#  + sum{(p, source, sink, m) in process__source__sink__ramp_method : m in ramp_cost_method}
#      + r_cost_process_ramp_cost_dt[p, d, t]
  + sum{p in process_online : pdProcess[p, 'startup_cost', d]} r_cost_startup_dt[p, d, t]
;

param r_costPenalty_dt{(d, t) in dt} :=
  + sum{n in (nodeBalance union nodeBalancePeriod), ud in upDown} r_costPenalty_nodeState_upDown_dt[n, ud, d, t]
  + sum{g in groupInertia} r_costPenalty_inertia_dt[g, d, t]
  + sum{g in groupNonSync} r_costPenalty_non_synchronous_dt[g, d, t]
  + sum{(r, ud, ng) in reserve__upDown__group} r_costPenalty_reserve_upDown_dt[r, ud, ng, d, t]
;

param r_costOper_and_penalty_dt{(d, t) in dt} :=
  + r_costOper_dt[d, t]
  + r_costPenalty_dt[d, t]
;

param r_cost_process_other_operational_cost_d{p in process, d in d_realized_period} := sum{(d, t) in dt_realize_dispatch} r_cost_process_other_operational_cost_dt[p, d, t];
param r_cost_co2_d{d in d_realized_period} := sum{(g, c, n, d, t) in gcndt_co2_price: (d, t) in dt_realize_dispatch} r_cost_co2_dt[g, c, n, d, t];
param r_cost_commodity_d{d in d_realized_period} := sum{(c, n) in commodity_node, (d, t) in dt_realize_dispatch} r_cost_commodity_dt[c, n, d, t];
param r_cost_variable_d{d in d_realized_period} := sum{p in process} r_cost_process_other_operational_cost_d[p, d];
#param r_cost_ramp_d{d in d_realized_period} := sum{(p, source, sink, m) in process__source__sink__ramp_method, (d, t) in dt_realize_dispatch : m in ramp_cost_method} r_cost_process_ramp_cost_dt[p, d, t];
param r_cost_startup_d{d in d_realized_period} := sum{p in process_online, (d, t) in dt_realize_dispatch : pdProcess[p, 'startup_cost', d]} r_cost_startup_dt[p, d, t];

param r_costPenalty_nodeState_upDown_d{n in nodeBalance union nodeBalancePeriod, ud in upDown, d in d_realized_period} := sum{(d, t) in dt_realize_dispatch} r_costPenalty_nodeState_upDown_dt[n, ud, d, t];
param r_costPenalty_inertia_d{g in groupInertia, d in d_realized_period} := sum{(d, t) in dt_realize_dispatch} r_costPenalty_inertia_dt[g, d, t];
param r_costPenalty_non_synchronous_d{g in groupNonSync, d in d_realized_period} := sum{(d, t) in dt_realize_dispatch} r_costPenalty_non_synchronous_dt[g, d, t];
param r_costPenalty_reserve_upDown_d{(r, ud, ng) in reserve__upDown__group, d in d_realized_period} := sum{(d, t) in dt_realize_dispatch} r_costPenalty_reserve_upDown_dt[r, ud, ng, d, t];

param r_costOper_d{d in period} := sum{(d, t) in dt} r_costOper_dt[d, t] ;
param r_costPenalty_d{d in period} := sum{(d, t) in dt} r_costPenalty_dt[d, t] + sum{g in groupCapacityMargin : d in period_invest} r_costPenalty_capacity_margin_d[g, d];
param r_costOper_and_penalty_d{d in period} := + r_costOper_d[d] + r_costPenalty_d[d];

param r_costInvestUnit_d{d in period} := sum{(e, d) in ed_invest : e in process_unit} r_cost_entity_invest_d[e, d];
param r_costDivestUnit_d{d in period} := sum{(e, d) in ed_divest : e in process_unit} r_cost_entity_divest_d[e, d];
param r_costInvestConnection_d{d in period} := sum{(e, d) in ed_invest : e in process_connection} r_cost_entity_invest_d[e, d];
param r_costDivestConnection_d{d in period} := sum{(e, d) in ed_divest : e in process_connection} r_cost_entity_divest_d[e, d];
param r_costInvestState_d{d in period} := sum{(e, d) in ed_invest : e in nodeState} r_cost_entity_invest_d[e, d];
param r_costDivestState_d{d in period} := sum{(e, d) in ed_divest : e in nodeState} r_cost_entity_divest_d[e, d];

param r_costInvest_d{d in period} := r_costInvestUnit_d[d] + r_costInvestConnection_d[d] + r_costInvestState_d[d];
param r_costDivest_d{d in period} := r_costDivestUnit_d[d] + r_costDivestConnection_d[d] + r_costDivestState_d[d];
param r_costExistingFixed_d{d in period} := sum{e in entity : (e, d) not in ed_invest} r_cost_entity_existing_fixed[e, d];

param pdNodeInflow{n in node, d in period} := 
  + (if n in nodeBalance && (n, 'no_inflow') not in node__inflow_method then sum{(d, t) in dt} pdtNodeInflow[n, d, t])
  + (if n in nodeBalancePeriod then pdNode[n, 'annual_flow', d]);


param potentialVREgen_dt{(p, n) in process_sink, (d, t) in dt_realize_dispatch:  p in process_VRE} :=
  + sum{(p, source, n, f, m) in process__source__sink__profile__profile_method: m = 'upper_limit'} 
      + pdtProfile[f, d, t] * entity_all_capacity[p, d]
        * pdtProcess[p, 'availability', d, t]
        / (if (p, 'min_load_efficiency') in process__ct_method then pdtProcess_slope[p, d, t] else 1 / pdtProcess[p, 'efficiency', d, t])
      + ( if (p, 'min_load_efficiency') in process__ct_method then 
            ( + (if p in process_online_linear then v_online_linear[p, d, t]) 
              + (if p in process_online_integer then v_online_integer[p, d, t])
            )
            * pdtProcess_section[p, d, t] * p_entity_unitsize[p]
            * pdtProcess[p, 'availability', d, t]
        );

param potentialVREgen{(p, n) in process_sink, d in d_realized_period : p in process_VRE} :=
  + sum{(p, source, n, f, m) in process__source__sink__profile__profile_method, (d, t) in dt_realize_dispatch : m = 'upper_limit'} 
      + potentialVREgen_dt[p, n, d, t];

param r_group_output__group_aggregate_Unit_to_group__dt{(g, ga) in group_output__group_aggregate_Unit_to_group, (d, t) in dt_realize_dispatch} :=
  + sum{(g, ga, u, source, sink) in group_output__group_aggregate__process__unit__to_node}  
      + r_process__source__sink_Flow__dt[u, source, sink, d, t];
param r_group_output__group_aggregate_Unit_to_group__d{(g, ga) in group_output__group_aggregate_Unit_to_group, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_output__group_aggregate_Unit_to_group__dt[g, ga, d, t];

param r_group_output__group_aggregate_Group_to_unit__dt{(g, ga) in group_output__group_aggregate_Group_to_unit, (d, t) in dt_realize_dispatch} :=
  + sum{(g, ga, u, source, sink) in group_output__group_aggregate__process__node__to_unit}  
      - r_process__source__sink_Flow__dt[u, source, sink, d, t];
param r_group_output__group_aggregate_Group_to_unit__d{(g, ga) in group_output__group_aggregate_Group_to_unit, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_output__group_aggregate_Group_to_unit__dt[g, ga, d, t];

param r_group_output__group_aggregate_Connection__dt{(g, ga) in group_output__group_aggregate_Connection, (d, t) in dt_realize_dispatch} :=
  + sum{(g, ga, c, source, sink) in group_output__group_aggregate__process__connection__to_node}
    ( + r_process__source__sink_Flow__dt[c, c, sink, d, t])
  + sum{(g, ga, c, source, sink) in group_output__group_aggregate__process__node__to_connection}
    ( - r_process__source__sink_Flow__dt[c, source, c, d, t]);
param r_group_output__group_aggregate_Connection__d{(g, ga) in group_output__group_aggregate_Connection, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_output__group_aggregate_Connection__dt[g, ga, d, t];

param r_group_output_Internal_connection_losses__dt{g in groupOutputNodeFlows, (d,t) in dt_realize_dispatch} :=
  + sum{(c, source, sink) in process_source_sink_alwaysProcess : c in process_connection && (c, source) in process_source && (g, c) in group_output__process_fully_inside}
      + r_process__source__sink_Flow__dt[c, source, sink, d, t]
  - sum{(c, source, sink) in process_source_sink_alwaysProcess : c in process_connection && (c, sink) in process_sink && (g, c) in group_output__process_fully_inside}
      + r_process__source__sink_Flow__dt[c, source, sink, d, t]
  + sum{(c, source, sink) in process_source_sink_alwaysProcess : c in process_connection && (c, source) in process_sink && (g, c) in group_output__process_fully_inside}
      + r_process__source__sink_Flow__dt[c, source, sink, d, t]
  - sum{(c, source, sink) in process_source_sink_alwaysProcess : c in process_connection && (c, sink) in process_source && (g, c) in group_output__process_fully_inside}
      + r_process__source__sink_Flow__dt[c, source, sink, d, t];
param r_group_output_Internal_connection_losses__d{g in groupOutputNodeFlows, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_output_Internal_connection_losses__dt[g, d, t];

param r_group_output_Internal_unit_losses__dt{g in groupOutputNodeFlows, (d,t) in dt_realize_dispatch} :=
  + sum{(u, source, sink) in process_source_sink_alwaysProcess:
    u in process_unit && (g, u) in group_output__process_fully_inside && (g,source) in group_node}
    + r_process__source__sink_Flow__dt[u, source, sink, d, t] 
  - sum{(u, source, sink) in process_source_sink_alwaysProcess:
    u in process_unit && (g, u) in group_output__process_fully_inside && (g,sink) in group_node}
    + r_process__source__sink_Flow__dt[u, source, sink, d, t];
param r_group_output_Internal_unit_losses__d{g in groupOutputNodeFlows, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_output_Internal_unit_losses__dt[g, d, t];

param r_group_node_inflow__dt{g in groupOutputNodeFlows, (d,t) in dt_realize_dispatch} :=
  + sum{(g,n) in group_node : (n, 'no_inflow') not in node__inflow_method}
    +pdtNodeInflow[n, d, t];
param r_group_node_inflow__d{g in groupOutputNodeFlows, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_node_inflow__dt[g, d, t];
    
param r_group_node_state_losses__dt{g in groupOutputNodeFlows, (d,t) in dt_realize_dispatch} :=
  + sum{n in nodeSelfDischarge: (g,n) in group_node}
    +r_selfDischargeLoss_dt[n, d, t];
param r_group_node_state_losses__d{g in groupOutputNodeFlows, d in d_realized_period}:=
  + sum{(d, t) in dt_realize_dispatch} r_group_node_state_losses__dt[g, d, t];

param r_group_node_up_penalties__dt{g in groupOutputNodeFlows, (d,t) in dt_realize_dispatch} :=
  + sum{n in (nodeBalance union nodeBalancePeriod): (g,n) in group_node}
    +vq_state_up[n, d, t].val * node_capacity_for_scaling[n, d] * step_duration[d, t] ;  
param r_group_node_up_penalties__d{g in groupOutputNodeFlows, d in d_realized_period}:=
  + sum{(d, t) in dt_realize_dispatch} r_group_node_up_penalties__dt[g, d, t];

param r_group_node_down_penalties__dt{g in groupOutputNodeFlows, (d,t) in dt_realize_dispatch} :=
  + sum{n in (nodeBalance union nodeBalancePeriod): (g,n) in group_node}
    -vq_state_down[n, d, t].val * node_capacity_for_scaling[n, d] * step_duration[d, t] ;  
param r_group_node_down_penalties__d{g in groupOutputNodeFlows, d in d_realized_period} :=
  + sum{(d, t) in dt_realize_dispatch} r_group_node_down_penalties__dt[g, d, t];

param r_storage_usage_dt{(n,'fix_usage') in node__storage_nested_fix_method, (d, t) in dt_fix_storage_timesteps}:=
    + sum{(p, n, sink) in process_source_sink_alwaysProcess} r_process__source__sink_Flow__dt[p, n, sink, d, t] * step_duration[d,t]
    - sum{(p, source, n) in process_source_sink_alwaysProcess} r_process__source__sink_Flow__dt[p, source, n, d, t] * step_duration[d,t]
    ;
  
param fn_entity_period_existing_capacity symbolic := "solve_data/p_entity_period_existing_capacity.csv";
printf 'entity,period,p_entity_period_existing_capacity,p_entity_period_invested_capacity\n' > fn_entity_period_existing_capacity;
for {(e, d) in ed_history_realized union {e in entity, d in d_realize_invest}}
  {
    printf '%s,%s,%.12g,%.12g\n', e, d,
	  + (if p_model['solveFirst'] && e in process && d in period_first then p_process[e, 'existing'])
	  + (if p_model['solveFirst'] && e in node    && d in period_first then    p_node[e, 'existing'])
	  + (if not p_model['solveFirst'] && (e, d) in ed_history_realized then p_entity_period_existing_capacity[e, d])
	  + (if (e, d) in ed_invest && d in d_realize_invest then ( v_invest[e, d].val ) * p_entity_unitsize[e]),
	  + (if not p_model['solveFirst'] && (e, d) in ed_history_realized  then p_entity_period_invested_capacity[e, d])
	  + (if (e, d) in ed_invest && d in d_realize_invest then ( v_invest[e, d].val ) * p_entity_unitsize[e])
	>> fn_entity_period_existing_capacity;
  }
  
printf 'Transfer divestments to the next solve...\n';
param fn_entity_divested symbolic := "solve_data/p_entity_divested.csv";
printf 'entity,p_entity_divested\n' > fn_entity_divested;
for {e in entityDivest} 
  {
    printf '%s,%.12g\n', e, 
	  + (if not p_model['solveFirst'] then p_entity_divested[e] else 0)
	  + sum {(e, d_divest) in ed_divest} v_divest[e, d_divest].val * p_entity_unitsize[e]
	>> fn_entity_divested;
  }

printf 'Write node state quantity for fixed timesteps ..\n';
param fn_fix_quantity_nodeState__dt symbolic := "solve_data/fix_storage_quantity.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'period,step,node,p_fix_storage_quantity\n' > fn_fix_quantity_nodeState__dt;
  }
for {(d,t) in period__time_first: (d, t) in dt_fix_storage_timesteps} #clear also after before each time values are outputted, to avoid duplicates
  { printf 'period,step,node,p_fix_storage_quantity\n' > fn_fix_quantity_nodeState__dt;
  }
for {(n,'fix_quantity') in node__storage_nested_fix_method, (d, t) in dt_fix_storage_timesteps}
  {
    printf '%s,%s,%s,%.12g\n', d, t, n, v_state[n, d, t].val * p_entity_unitsize[n]>> fn_fix_quantity_nodeState__dt;
  }

printf 'Write node state price for fixed timesteps ..\n';
param fn_fix_price_nodeState__dt symbolic := "solve_data/fix_storage_price.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'period,step,node,p_fix_storage_price\n' > fn_fix_price_nodeState__dt;
  }
for {(d,t) in period__time_first: (d, t) in dt_fix_storage_timesteps} #clear also after before each time values are outputted, to avoid duplicates
  { printf 'period,step,node,p_fix_storage_price\n' > fn_fix_price_nodeState__dt;
  }
for {c in solve_current, (n,'fix_price') in node__storage_nested_fix_method, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt: (d, t) in dt_fix_storage_timesteps}
  {
    printf '%s,%s,%s,%.12g\n', d, t, n,  -nodeBalance_eq[c, n, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve].dual / p_discount_factor_operations_yearly[d] * complete_period_share_of_year[d] / scale_the_objective >> fn_fix_price_nodeState__dt;
  }

printf 'Write node state usage for fixed timesteps ..\n';
param fn_fix_usage_nodeState__dt symbolic := "solve_data/fix_storage_usage.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'period,step,node,p_fix_storage_usage\n' > fn_fix_usage_nodeState__dt;
  }
for {(d,t) in period__time_first: (d, t) in dt_fix_storage_timesteps} #clear also after before each time values are outputted, to avoid duplicates
  { printf 'period,step,node,p_fix_storage_usage\n' > fn_fix_usage_nodeState__dt;
  }
for {(n,'fix_usage') in node__storage_nested_fix_method, (d, t) in dt_fix_storage_timesteps}
  {
    printf '%s,%s,%s,%.12g\n', d, t, n, r_storage_usage_dt[n,d,t] >> fn_fix_usage_nodeState__dt;
  }

printf 'Write node state last timestep ..\n';
param fn_p_roll_continue_state symbolic := "solve_data/p_roll_continue_state.csv";
# write over only if in a dispatch roll, storage solve should not create this
for {n in nodeState, (d, t) in realized_period__time_last}
  {
    printf 'node,p_roll_continue_state\n' > fn_p_roll_continue_state;
  }
for {n in nodeState, (d, t) in realized_period__time_last}
  {
    printf '%s,%.12g\n', n, v_state[n, d, t].val* p_entity_unitsize[n]  >> fn_p_roll_continue_state;
  }

printf 'Write unit capacity results...\n';
param fn_unit_capacity symbolic := "output/unit_capacity__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'unit,solve,period,existing,invested,divested,total\n' > fn_unit_capacity; }  # Clear the file on the first solve
for {s in solve_current, p in process_unit, d in d_realize_invest: 'yes' not in exclude_entity_outputs}
  {
    printf '%s,%s,%s,%.8g,%.8g,%.8g,%.8g\n', p, s, d, 
	        p_entity_all_existing[p, d], 
			(if (p, d) in pd_invest then v_invest[p, d].val * p_entity_unitsize[p] else 0), 
			(if (p, d) in pd_divest then v_divest[p, d].val * p_entity_unitsize[p] else 0), 
			entity_all_capacity[p, d]
#			+ (if entity_all_capacity[p, d] then sum{(p, sink) in process_sink} (r_process_sink_flow_d[p, sink, d]) / entity_all_capacity[p,d] else 0),
#			+ r_cost_process_other_operational_cost_d[p, d]
	>> fn_unit_capacity;
  }

printf 'Write connection capacity results...\n';
param fn_connection_capacity symbolic := "output/connection_capacity__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'connection,solve,period,existing,invested,divested,total\n' > fn_connection_capacity; }  # Clear the file on the first solve
for {s in solve_current, p in process_connection, d in d_realize_invest: 'yes' not in exclude_entity_outputs}
  {
    printf '%s,%s,%s,%.8g,%.8g,%.8g,%.8g\n', p, s, d, 
	        p_entity_all_existing[p, d],
			(if (p, d) in pd_invest then v_invest[p, d].val * p_entity_unitsize[p] else 0),
			(if (p, d) in pd_divest then v_divest[p, d].val * p_entity_unitsize[p] else 0),
			+ entity_all_capacity[p, d] 
	>> fn_connection_capacity;
  }

printf 'Write node/storage capacity results...\n';
param fn_node_capacity symbolic := "output/node_capacity__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'node,solve,period,existing,invested,divested,total\n' > fn_node_capacity; }  # Clear the file on the first solve
for {s in solve_current, e in nodeState, d in d_realize_invest: 'yes' not in exclude_entity_outputs}
  {
    printf '%s,%s,%s,%.8g,%.8g,%.8g,%.8g\n', e, s, d, 
	        p_entity_all_existing[e, d],
			(if (e, d) in ed_invest then v_invest[e, d].val * p_entity_unitsize[e] else 0),
			(if (e, d) in ed_divest then v_divest[e, d].val * p_entity_unitsize[e] else 0),
			+ entity_all_capacity[e, d]
	 >> fn_node_capacity;
  }

param w_capacity := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve;
display w_capacity;

printf 'Write summary results...\n';
param fn_summary symbolic := "output/summary_solve.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf '"Diagnostic results from all solves. Output at (UTC): %s"', time2str(gmtime(), "%FT%TZ") > fn_summary; }
for {s in solve_current} { printf '\n\n"Solve",%s\n', s >> fn_summary; }
printf '"Total cost obj. function (M CUR)",%.12g,"Minimized total system cost as ', (total_cost.val / scale_the_objective / 1000000) >> fn_summary;
printf 'given by the solver (includes all penalty costs)"\n' >> fn_summary;
printf '"Total cost (calculated) full horizon (M CUR)",%.12g,', sum{d in period_in_use} 
           ( + r_costOper_and_penalty_d[d] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] 
		     + r_costInvest_d[d]
			 + r_costDivest_d[d]
		   ) / 1000000 >> fn_summary;
printf '"Annualized operational, penalty and investment costs"\n' >> fn_summary;
printf '"Total cost (calculated) realized periods (M CUR)",%.12g\n', sum{d in period_in_use} 
           ( + r_costOper_and_penalty_d[d] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] 
		     + r_costInvest_d[d]
			 + r_costDivest_d[d]
		   ) / 1000000 >> fn_summary;
printf '"Operational costs for realized periods (M CUR)",%.12g\n', sum{d in d_realized_period} 
           + r_costOper_d[d] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] / 1000000>> fn_summary;
printf '"Investment costs for realized periods (M CUR)",%.12g\n', sum{d in d_realize_invest} 
           + r_costInvest_d[d] / 1000000 >> fn_summary;
printf '"Retirement costs (negative salvage value) for realized periods (M CUR)",%.12g\n', sum{d in d_realize_invest} 
           + r_costDivest_d[d] / 1000000 >> fn_summary;
printf '"Fixed costs for existing units (M CUR)",%.12g\n', sum{d in d_realize_invest} r_costExistingFixed_d[d] / 1000000 >> fn_summary;
printf '"Penalty (slack) costs for realized periods (M CUR)",%.12g\n', sum{d in d_realized_period} 
           + r_costPenalty_d[d] * p_discount_factor_operations_yearly[d] / complete_period_share_of_year[d] / 1000000 >> fn_summary;
printf '\nPeriod' >> fn_summary;
for {d in period}
  { printf ',%s', d >> fn_summary; }
printf '\n"Time in use in years"' >> fn_summary;
for {d in period}
  { printf ',%.12g', complete_period_share_of_year[d] >> fn_summary; }
printf '\n"Operational discount factor"' >> fn_summary;
for {d in period}
  { printf ',%.12g', p_discount_factor_operations_yearly[d] >> fn_summary; }
printf '\n"Investment discount factor"' >> fn_summary;
for {d in period}
  { printf ',%.12g', p_discount_factor_operations_yearly[d] >> fn_summary; }
printf '\n' >> fn_summary;

printf '\nEmissions\n' >> fn_summary;
printf '"CO2 (Mt)",%.6g,"System-wide annualized CO2 emissions for all periods"\n', sum{(c, n) in commodity_node_co2, d in d_realized_period} (r_emissions_co2_d[c, n, d] ) / 1000000 >> fn_summary;
printf '"CO2 (Mt)",%.6g,"System-wide annualized CO2 emissions for realized periods"\n', sum{(c, n) in commodity_node_co2, d in d_realized_period} (r_emissions_co2_d[c, n, d]) / 1000000 >> fn_summary;

printf '\n"Slack variables (creating or removing energy/matter, creating inertia, ' >> fn_summary;
printf 'changing non-synchronous generation to synchronous)"\n' >> fn_summary;
for {n in nodeBalance union nodeBalancePeriod}
  {  
    for {d in d_realized_period : r_penalty_nodeState_upDown_d[n, 'up', d]}
      {
	    printf 'Created, %s, %s, %.5g\n', n, d, r_penalty_nodeState_upDown_d[n, 'up', d] >> fn_summary;
      }
  }

for {n in nodeBalance union nodeBalancePeriod}
  {  
    for {d in d_realized_period : r_penalty_nodeState_upDown_d[n, 'down', d]}
      {
	    printf 'Removed, %s, %s, %.5g\n', n, d, r_penalty_nodeState_upDown_d[n, 'down', d] >> fn_summary;
      }
  }

for {g in groupInertia}
  {
    for {d in d_realized_period : r_costPenalty_inertia_d[g, d]}
	  {
        printf 'Inertia, %s, %s, %.5g\n', g, d, r_costPenalty_inertia_d[g, d] / pdGroup[g, 'penalty_inertia', d] >> fn_summary;
	  }
  }

for {g in groupNonSync}
  {
    for {d in d_realized_period : r_costPenalty_non_synchronous_d[g, d]}
	  {
        printf 'NonSync, %s, %s, %.5g\n', g, d, r_costPenalty_non_synchronous_d[g, d] / pdGroup[g, 'penalty_non_synchronous', d] >> fn_summary;
	  }
  }

for {g in groupCapacityMargin}
  {
    for {d in period_invest : r_costPenalty_capacity_margin_d[g, d]}
	  {
        printf 'CapMargin, %s, %s, %.5g\n', g, d, r_costPenalty_capacity_margin_d[g, d] / pdGroup[g, 'penalty_capacity_margin', d] >> fn_summary;
	  }
  }

param w_summary := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity;
display w_summary;

printf 'Write group results for nodes for realized periods...\n';
param fn_groupNode__d symbolic := "output/group_node__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'group,solve,period,"sum of annualized inflows [MWh]","VRE share [of annual inflow]",' > fn_groupNode__d;
	printf '"curtailed VRE share, [of annual inflow]","upward slack [of annual inflow]",' >> fn_groupNode__d;
	printf '"downward slack [of annual inflow]"\n' >> fn_groupNode__d;
  }
for {g in groupOutput_node, s in solve_current, d in d_realized_period: sum{(g, n) in group_node} pdNodeInflow[n, d]}
  {
    printf '%s,%s,%s,%.8g,%.6f,%.6f,%.6f,%.6f\n', g, s, d 
       , sum{(g, n) in group_node} pdNodeInflow[n, d] / complete_period_share_of_year[d]
       , ( sum{(p, source, n) in process_source_sink_alwaysProcess : (g, n) in group_node && p in process_VRE && (p, n) in process_sink} 
	             r_process_source_sink_flow_d[p, source, n, d]  
		 ) / ( - sum{(g, n) in group_node} pdNodeInflow[n, d] / complete_period_share_of_year[d] )	   
	   , ( + sum{(p, n) in process_sink : (g, n) in group_node && p in process_VRE} potentialVREgen[p, n, d]
	       - sum{(p, source, n) in process_source_sink_alwaysProcess : (g, n) in group_node && p in process_VRE && (p, n) in process_sink} 
		         r_process_source_sink_flow_d[p, source, n, d] 
		 ) / ( - sum{(g, n) in group_node} pdNodeInflow[n, d] / complete_period_share_of_year[d] )
	  , ( sum{(g, n) in group_node : n in nodeBalance union nodeBalancePeriod} r_penalty_nodeState_upDown_d[n, 'up', d] ) 
	    / ( - sum{(g, n) in group_node} pdNodeInflow[n, d] / complete_period_share_of_year[d] )
	  , ( sum{(g, n) in group_node : n in nodeBalance union nodeBalancePeriod} r_penalty_nodeState_upDown_d[n, 'down', d] ) 
	    / ( - sum{(g, n) in group_node} pdNodeInflow[n, d] / complete_period_share_of_year[d] )
	>> fn_groupNode__d;
  }

printf 'Write group results for realized time steps...\n';
param fn_groupNode__dt symbolic := "output/group_node__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'group,solve,period,time,' > fn_groupNode__dt;
	printf '"pdtNodeInflow" ,"sum of annualized inflows [MWh]","VRE share [of annual inflow]",' >> fn_groupNode__dt;
  printf '"curtailed VRE share, [of annual inflow]","upward slack [of annual inflow]",' >> fn_groupNode__dt;
	printf '"downward slack [of annual inflow]"\n' >> fn_groupNode__dt;
  }
for {g in groupOutput_node, s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '%s,%s,%s,%s,%.8g,%.8g,%.6f,%.6f,%.6f,%.6f\n', g, s, d, t
     , ( - sum{(g, n) in group_node : (n, 'no_inflow') not in node__inflow_method} pdtNodeInflow[n, d, t] )
     , sum{(g, n) in group_node : (n, 'no_inflow') not in node__inflow_method} pdtNodeInflow[n, d, t] / complete_period_share_of_year[d]
     , ( sum{(p, source, n) in process_source_sink_alwaysProcess : (g, n) in group_node && p in process_VRE && (p, n) in process_sink} 
            r_process__source__sink_Flow__dt[p, source, n, d, t]  
		 )   
	   , ( + sum{(p, n) in process_sink : p in process_VRE} potentialVREgen_dt[p, n, d, t]
	       - sum{(p, source, n) in process_source_sink_alwaysProcess : (g, n) in group_node && p in process_VRE && (p, n) in process_sink} 
		         r_process__source__sink_Flow__dt[p, source, n, d, t] 
		 ) 
	   , ( sum{(g, n) in group_node : n in nodeBalance union nodeBalancePeriod} r_costPenalty_nodeState_upDown_dt[n, 'up', d, t] / pdtNode[n, 'penalty_up', d, t]) 
	   , ( sum{(g, n) in group_node : n in nodeBalance union nodeBalancePeriod} r_costPenalty_nodeState_upDown_dt[n, 'down', d, t] / pdtNode[n, 'penalty_down', d, t] ) 
	>> fn_groupNode__dt;
  }

printf 'Write VRE share for node groups for realized timesteps\n';
param fn_groupNode__dt_VRE_share symbolic := "output/group_node_VRE_share__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period,time' > fn_groupNode__dt_VRE_share;
	for {g in groupOutput_node : sum{(g, n) in group_node, d in period} pdNodeInflow[n, d]}
	  { printf ',%s', g >> fn_groupNode__dt_VRE_share; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_groupNode__dt_VRE_share;
	for {g in groupOutput_node : sum{(g, n) in group_node} pdNodeInflow[n, d]}
	  { printf ',%.6f',
	      ( if sum{(g, n) in group_node} pdtNodeInflow[n, d, t] then
              ( sum{(p, source, n) in process_source_sink_alwaysProcess : (g, n) in group_node && p in process_VRE && (p, n) in process_sink} 
	                 r_process__source__sink_Flow__dt[p, source, n, d, t]  
		      ) / ( - sum{(g, n) in group_node} pdtNodeInflow[n, d, t] )
		  
		)
	    >> fn_groupNode__dt_VRE_share;
	  }
  }

printf 'Write annualized CO2 Mt results for groups for realized periods...\n';
param fn_groupNode__d_CO2 symbolic := "output/group_process_CO2__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period' > fn_groupNode__d_CO2;
	for {g in groupOutput : sum{(p, c, n) in process__commodity__node_co2 : (g, p) in group_process} 1}
	  { printf ',%s', g >> fn_groupNode__d_CO2; }
  }
for {s in solve_current, d in d_realized_period}
  {
    printf '\n%s,%s', s, d >> fn_groupNode__d_CO2;
	for {g in groupOutput : sum{(p, c, n) in process__commodity__node_co2 : (g, p) in group_process} 1}
	  { printf ',%.6f',
	      sum{(p, c, n) in process__commodity__node_co2 : (g, p) in group_process}
		      r_process_emissions_co2_d[p, c, n, d] / 1000000
		>> fn_groupNode__d_CO2;
	  }
  }

printf 'Write results for groups for realized periods...\n';
param fn_groupProcessNode__d symbolic := "output/group__process__node__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period' > fn_groupProcessNode__d;
	for {g in groupOutput_process}
	  {
	    printf ',%s', g >> fn_groupProcessNode__d;
	  }
  }
for {s in solve_current, d in d_realized_period}
  {
    printf '\n%s,%s', s, d >> fn_groupProcessNode__d;
  for {g in groupOutput_process}
    {
      printf ',%.8g', 
          + sum{(p, source, n) in process_source_sink_alwaysProcess : (g, p, n) in group_process_node && (p, n) in process_sink} 
                r_process_source_sink_flow_d[p, source, n, d] / complete_period_share_of_year[d] 
          + sum{(p, n, sink) in process_source_sink_alwaysProcess : (g, p, n) in group_process_node && (p, n) in process_source} 
              r_process_source_sink_flow_d[p, n, sink, d] / complete_period_share_of_year[d]
      >> fn_groupProcessNode__d;
    }
  }

printf 'Write flow results for groups for realized time steps...\n';
param fn_groupProcessNode__dt symbolic := "output/group__process__node__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period,time' > fn_groupProcessNode__dt;
	for {g in groupOutput_process}
	  {
	    printf ',%s', g >> fn_groupProcessNode__dt;
	  }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_groupProcessNode__dt;
	for {g in groupOutput_process}
	  {
	    printf ',%.8g',
         + sum{(p, source, n) in process_source_sink_alwaysProcess : (g, p, n) in group_process_node && (p, n) in process_sink} 
	             r_process__source__sink_Flow__dt[p, source, n, d, t]
         + sum{(p, n, sink) in process_source_sink_alwaysProcess : (g, p, n) in group_process_node && (p, n) in process_source} 
		         r_process__source__sink_Flow__dt[p, n, sink, d, t]
	    >> fn_groupProcessNode__dt;
	  }
  }

param w_group := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_summary;
display w_group;

printf 'Write discount rates for realized periods...\n';
param fn_discount symbolic := "output/discount_factors__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period,"operations discount factor",' > fn_discount;
	printf '"investments discount factor"\n' >> fn_discount;
  }
for {s in solve_current, d in d_realize_invest}
  { 
    printf '%s,%s,%.12g,%.12g\n', 
      s, d,
	  p_discount_factor_operations_yearly[d],
	  p_discount_factor_operations_yearly[d]
	>> fn_discount;
  }

printf 'Write investment annuities for each entity...\n';
param fn_annuity symbolic := "output/entity_annuity.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period' > fn_annuity;
	for {e in entity : e in entityInvest} printf ',%s', e >> fn_annuity;
	  printf '\n' >> fn_annuity;
  }
for {s in solve_current, d in d_realize_invest}
  { 
    printf '%s,%s', s, d >> fn_annuity;
	for {e in entityInvest}
	  printf ',%.12g', ed_entity_annual[e, d] >> fn_annuity;
	printf '\n' >> fn_annuity;
  }

display complete_period_share_of_year;
display p_discount_factor_operations_yearly;
printf 'Write discounted total cost for each cost type per solve...\n';
param fn_costs_total_discounted symbolic := "output/costs_discounted__solve.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,"unit investment/retirement","connection investment/retirement",' > fn_costs_total_discounted;
    printf '"storage investment/retirement","fixed cost of existing assets",commodity,CO2,' >> fn_costs_total_discounted;
	printf '"variable cost",starts,"upward penalty","downward penalty","inertia penalty",' >> fn_costs_total_discounted;
	printf '"non-synchronous penalty","capacity margin penalty","upward reserve penalty",' >> fn_costs_total_discounted;
	printf '"downward reserve penalty"\n' >> fn_costs_total_discounted;
  }
for {s in solve_current}
  {
    printf '%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', 
      s,
	  sum{d in d_realize_invest} (r_costInvestUnit_d[d] + r_costDivestUnit_d[d]) / 1000000,
    sum{d in d_realize_invest} (r_costInvestConnection_d[d] + r_costDivestConnection_d[d]) / 1000000,
    sum{d in d_realize_invest} (r_costInvestState_d[d] + r_costDivestState_d[d]) / 1000000,
	  sum{d in d_realize_invest} (r_costExistingFixed_d[d]) / 1000000,
	  sum{d in d_realized_period} (r_cost_commodity_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000,
	  sum{d in d_realized_period} (r_cost_co2_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000,
	  sum{d in d_realized_period} (r_cost_variable_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000,
	  sum{d in d_realized_period} (r_cost_startup_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000,
	  sum{d in d_realized_period} (sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_d[n, 'up', d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000,
	  sum{d in d_realized_period} (sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_d[n, 'down', d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000,
	  sum{d in d_realized_period} (sum{g in groupInertia} (r_costPenalty_inertia_d[g, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000,
	  sum{d in d_realized_period} (sum{g in groupNonSync} (r_costPenalty_non_synchronous_d[g, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000,
	  sum{d in d_realize_invest} (sum{g in groupCapacityMargin} (r_costPenalty_capacity_margin_d[g, d])) / 1000000,	
	  sum{d in d_realized_period} (sum{(r, ud, ng) in reserve__upDown__group : ud = 'up'} (r_costPenalty_reserve_upDown_d[r, ud, ng, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000,
	  sum{d in d_realized_period} (sum{(r, ud, ng) in reserve__upDown__group : ud = 'down'} (r_costPenalty_reserve_upDown_d[r, ud, ng, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000
	>> fn_costs_total_discounted;
  } 

printf 'Write discounted total cost for each cost type summed for all solves so far...\n';
param fn_costs_discounted symbolic := "output/costs_discounted.csv";
printf 'param_costs,costs_discounted\n' > fn_costs_discounted;
printf '"unit investment/retirement",%.12g\n', costs_discounted["unit investment/retirement"] + sum{d in d_realize_invest} (r_costInvestUnit_d[d] + r_costDivestUnit_d[d]) / 1000000 >> fn_costs_discounted;
printf '"connection investment/retirement",%.12g\n', costs_discounted["connection investment/retirement"] + sum{d in d_realize_invest} (r_costInvestConnection_d[d] + r_costDivestConnection_d[d]) / 1000000 >> fn_costs_discounted;
printf '"storage investment/retirement",%.12g\n', costs_discounted["storage investment/retirement"] + sum{d in d_realize_invest} (r_costInvestState_d[d] + r_costDivestState_d[d]) / 1000000 >> fn_costs_discounted;
printf '"fixed cost of existing assets",%.12g\n', costs_discounted["fixed cost of existing assets"] + sum{d in d_realize_invest} (r_costExistingFixed_d[d]) / 1000000 >> fn_costs_discounted;
printf '"commodity",%.12g\n', costs_discounted["commodity"] + sum{d in d_realized_period} (r_cost_commodity_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000 >> fn_costs_discounted;
printf '"CO2",%.12g\n', costs_discounted["CO2"] + sum{d in d_realized_period} (r_cost_co2_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000 >> fn_costs_discounted;
printf '"variable cost",%.12g\n', costs_discounted["variable cost"] + sum{d in d_realized_period} (r_cost_variable_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000 >> fn_costs_discounted;
printf '"starts",%.12g\n', costs_discounted["starts"] + sum{d in d_realized_period} (r_cost_startup_d[d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d]) / 1000000 >> fn_costs_discounted;
printf '"upward penalty",%.12g\n', costs_discounted["upward penalty"] + sum{d in d_realized_period} (sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_d[n, 'up', d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000 >> fn_costs_discounted;
printf '"downward penalty",%.12g\n', costs_discounted["downward penalty"] + sum{d in d_realized_period} (sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_d[n, 'down', d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000 >> fn_costs_discounted;
printf '"inertia penalty",%.12g\n', costs_discounted["inertia penalty"] + sum{d in d_realized_period} (sum{g in groupInertia} (r_costPenalty_inertia_d[g, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000 >> fn_costs_discounted;
printf '"non-synchronous penalty",%.12g\n', costs_discounted["non-synchronous penalty"] + sum{d in d_realized_period} (sum{g in groupNonSync} (r_costPenalty_non_synchronous_d[g, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000 >> fn_costs_discounted;
printf '"capacity margin penalty",%.12g\n', costs_discounted["capacity margin penalty"] + sum{d in d_realize_invest} (sum{g in groupCapacityMargin} (r_costPenalty_capacity_margin_d[g, d])) / 1000000 >> fn_costs_discounted;
printf '"upward reserve penalty",%.12g\n', costs_discounted["upward reserve penalty"] + sum{d in d_realized_period} (sum{(r, ud, ng) in reserve__upDown__group : ud = 'up'} (r_costPenalty_reserve_upDown_d[r, ud, ng, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000 >> fn_costs_discounted;
printf '"downward reserve penalty",%.12g\n', costs_discounted["downward reserve penalty"] + sum{d in d_realized_period} (sum{(r, ud, ng) in reserve__upDown__group : ud = 'down'} (r_costPenalty_reserve_upDown_d[r, ud, ng, d] / complete_period_share_of_year[d] * p_discount_factor_operations_yearly[d])) / 1000000 >> fn_costs_discounted;

printf 'Write annualized cost summary for realized periods...\n';
param fn_summary_cost symbolic := "output/annualized_costs__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period,"unit investment/retirement","connection investment/retirement",' > fn_summary_cost;
    printf '"storage investment/retirement","fixed cost of existing assets","capacity margin penalty",' >> fn_summary_cost;
	printf '"commodity","CO2","variable cost",starts,"upward penalty","downward penalty","inertia penalty",' >> fn_summary_cost;
	printf '"non-synchronous penalty","upward reserve penalty",' >> fn_summary_cost;
	printf '"downward reserve penalty"\n' >> fn_summary_cost;
  }
for {s in solve_current, d in (d_realized_period union d_realize_invest)}
  { 
    printf '%s,%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', 
      s, d,
    (if d in d_realize_invest then (r_costInvestUnit_d[d] + r_costDivestUnit_d[d]) / p_discount_factor_operations_yearly[d] / 1000000 else 0),
    (if d in d_realize_invest then  (r_costInvestConnection_d[d] + r_costDivestConnection_d[d]) / p_discount_factor_operations_yearly[d] / 1000000 else 0),
    (if d in d_realize_invest then  (r_costInvestState_d[d] + r_costDivestState_d[d]) / p_discount_factor_operations_yearly[d] / 1000000 else 0),
	  (if d in d_realize_invest then  r_costExistingFixed_d[d] / p_discount_factor_operations_yearly[d] / 1000000 else 0),
    (if d in d_realize_invest then sum{g in groupCapacityMargin : d in period_invest} (r_costPenalty_capacity_margin_d[g, d] / p_discount_factor_operations_yearly[d]) / 1000000 else 0),
    (if d in d_realized_period then  r_cost_commodity_d[d] / complete_period_share_of_year[d] / 1000000 else 0),
	  (if d in d_realized_period then r_cost_co2_d[d] / complete_period_share_of_year[d] / 1000000 else 0),
	  (if d in d_realized_period then r_cost_variable_d[d] / complete_period_share_of_year[d] / 1000000 else 0),
	  (if d in d_realized_period then r_cost_startup_d[d] / complete_period_share_of_year[d] / 1000000 else 0),
	  (if d in d_realized_period then sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_d[n, 'up', d] / complete_period_share_of_year[d]) / 1000000 else 0),
	  (if d in d_realized_period then sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_d[n, 'down', d] / complete_period_share_of_year[d]) / 1000000 else 0),
	  (if d in d_realized_period then sum{g in groupInertia} (r_costPenalty_inertia_d[g, d] / complete_period_share_of_year[d]) / 1000000 else 0),
	  (if d in d_realized_period then sum{g in groupNonSync} (r_costPenalty_non_synchronous_d[g, d] / complete_period_share_of_year[d]) / 1000000 else 0),
	  (if d in d_realized_period then sum{(r, ud, ng) in reserve__upDown__group : ud = 'up'} (r_costPenalty_reserve_upDown_d[r, ud, ng, d] / complete_period_share_of_year[d]) / 1000000 else 0),
	  (if d in d_realized_period then sum{(r, ud, ng) in reserve__upDown__group : ud = 'down'} (r_costPenalty_reserve_upDown_d[r, ud, ng, d] / complete_period_share_of_year[d]) / 1000000  else 0)
	>> fn_summary_cost;
  } 

printf 'Write annualized investment cost summary for realized periods...\n';
param fn_annual_investment_summary_cost symbolic := "output/annualized_investment_costs__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period,"unit investment/retirement","connection investment/retirement",' > fn_annual_investment_summary_cost;
    printf '"storage investment/retirement","fixed cost of existing assets","capacity margin penalty"\n' >> fn_annual_investment_summary_cost;
  }
for {s in solve_current, d in d_realize_invest}
  {
    printf '%s,%s,%.12g,%.12g,%.12g,%.12g,%.12g\n', 
      s, d,
    (r_costInvestUnit_d[d] + r_costDivestUnit_d[d]) / p_discount_factor_operations_yearly[d] / 1000000,
    (r_costInvestConnection_d[d] + r_costDivestConnection_d[d]) / p_discount_factor_operations_yearly[d] / 1000000,
    (r_costInvestState_d[d] + r_costDivestState_d[d]) / p_discount_factor_operations_yearly[d] / 1000000,
	  r_costExistingFixed_d[d] / p_discount_factor_operations_yearly[d] / 1000000,
    sum{g in groupCapacityMargin : d in period_invest} (r_costPenalty_capacity_margin_d[g, d] / p_discount_factor_operations_yearly[d]) / 1000000
    >> fn_annual_investment_summary_cost;
  }

printf 'Write annualized dispatch cost summary for realized periods...\n';
param fn_annual_dispatch_summary_cost symbolic := "output/annualized_dispatch_costs__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
  printf 'solve,period,time,' > fn_annual_dispatch_summary_cost;
  printf 'commodity,CO2,' >> fn_annual_dispatch_summary_cost;
	printf '"variable cost",starts,"upward penalty","downward penalty","inertia penalty",' >> fn_annual_dispatch_summary_cost;
	printf '"non-synchronous penalty","upward reserve penalty",' >> fn_annual_dispatch_summary_cost;
	printf '"downward reserve penalty"\n' >> fn_annual_dispatch_summary_cost;
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  { 
    printf '%s,%s,%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', 
      s, d, t,
	  sum{(c, n) in commodity_node} r_cost_commodity_dt[c, n, d, t] / complete_period_share_of_year[d] / 1000000,
	  sum{(g, c, n, d, t) in gcndt_co2_price} r_cost_co2_dt[g, c, n, d, t] / complete_period_share_of_year[d] / 1000000,
	  sum{p in process} r_cost_process_other_operational_cost_dt[p, d, t] / complete_period_share_of_year[d] / 1000000,
	  sum{p in process_online : pdProcess[p, 'startup_cost', d]} r_cost_startup_dt[p, d, t] / complete_period_share_of_year[d] / 1000000,
	  sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_dt[n, 'up', d, t] / complete_period_share_of_year[d]) / 1000000,
	  sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_dt[n, 'down', d, t] / complete_period_share_of_year[d]) / 1000000,
	  sum{g in groupInertia} (r_costPenalty_inertia_dt[g, d, t] / complete_period_share_of_year[d]) / 1000000,
	  sum{g in groupNonSync} (r_costPenalty_non_synchronous_dt[g, d, t] / complete_period_share_of_year[d]) / 1000000,
	  sum{(r, ud, ng) in reserve__upDown__group : ud = 'up'} (r_costPenalty_reserve_upDown_dt[r, ud, ng, d, t] / complete_period_share_of_year[d]) / 1000000,
	  sum{(r, ud, ng) in reserve__upDown__group : ud = 'down'} (r_costPenalty_reserve_upDown_dt[r, ud, ng, d, t] / complete_period_share_of_year[d]) / 1000000
	>> fn_annual_dispatch_summary_cost;
  } 

param w_costs_period := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group;
display w_costs_period;

printf 'Write cost for realized periods and t...\n';
param fn_summary_cost_dt symbolic := "output/costs__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period,time,commodity,CO2,other_operational,starts,"upward slack penalty",' > fn_summary_cost_dt;
	printf '"downward slack penalty","inertia slack penalty","non-synchronous slack penalty",' >> fn_summary_cost_dt;
	printf '"upward reserve slack penalty","downward reserves slack penalty"\n' >> fn_summary_cost_dt;
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  { 
    printf '%s,%s,%s,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g,%.12g\n', 
      s, d, t,
	  sum{(c, n) in commodity_node} r_cost_commodity_dt[c, n, d, t],
	  sum{(g, c, n, d, t) in gcndt_co2_price} r_cost_co2_dt[g, c, n, d, t],
	  sum{p in process} r_cost_process_other_operational_cost_dt[p, d, t],
	  sum{p in process_online : pdProcess[p, 'startup_cost', d]} r_cost_startup_dt[p, d, t],
	  sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_dt[n, 'up', d, t]),
	  sum{n in nodeBalance union nodeBalancePeriod} (r_costPenalty_nodeState_upDown_dt[n, 'down', d, t]),
	  sum{g in groupInertia} (r_costPenalty_inertia_dt[g, d, t]),
	  sum{g in groupNonSync} (r_costPenalty_non_synchronous_dt[g, d, t]),
	  sum{(r, ud, ng) in reserve__upDown__group : ud = 'up'} (r_costPenalty_reserve_upDown_dt[r, ud, ng, d, t]),
	  sum{(r, ud, ng) in reserve__upDown__group : ud = 'down'} (r_costPenalty_reserve_upDown_dt[r, ud, ng, d, t])
	>> fn_summary_cost_dt;
  } 

param w_costs_time := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period;
display w_costs_time;

printf 'Write unit__outputNode flow for periods...\n';
param fn_unit__sinkNode__d symbolic := "output/unit__outputNode__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period' > fn_unit__sinkNode__d;  # Print the header on the first solve
	for {(u, sink) in process_sink : u in process_unit} printf ',%s', u >> fn_unit__sinkNode__d;
	printf '\n,' >> fn_unit__sinkNode__d;
	for {(u, sink) in process_sink : u in process_unit} printf ',%s', sink >> fn_unit__sinkNode__d;
  }
for {s in solve_current, d in d_realized_period: 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_unit__sinkNode__d;
    for {(u, sink) in process_sink : u in process_unit}
      { printf ',%.8g', r_process_sink_flow_d[u, sink, d] / complete_period_share_of_year[d] >> fn_unit__sinkNode__d; }
  } 

printf 'Write unit__outputNode flow for time...\n';
param fn_unit__sinkNode__dt symbolic := "output/unit__outputNode__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_unit__sinkNode__dt;  # Print the header on the first solve
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_unit} printf ',%s', u >> fn_unit__sinkNode__dt;
	printf '\n,,' >> fn_unit__sinkNode__dt;
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_unit} printf ',%s', sink >> fn_unit__sinkNode__dt;
  }
for {s in solve_current: 'output_unit__node_flow_t' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
  { printf '\n%s,%s,%s', s, d, t >> fn_unit__sinkNode__dt;
    for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_unit}
      { printf ',%.8g', r_process__source__sink_Flow__dt[u, source, sink, d, t] >> fn_unit__sinkNode__dt; }
  }}

printf 'Write unit__inputNode flow for periods...\n';
param fn_unit__sourceNode__d symbolic := "output/unit__inputNode__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period' > fn_unit__sourceNode__d;  # Print the header on the first solve
	for {(u, source) in process_source : u in process_unit} printf ',%s', u >> fn_unit__sourceNode__d;
	printf '\n,' >> fn_unit__sourceNode__d;
	for {(u, source) in process_source : u in process_unit} printf ',%s', source >> fn_unit__sourceNode__d;
  }
for {s in solve_current, d in d_realized_period: 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_unit__sourceNode__d;
    for {(u, source) in process_source : u in process_unit && 'yes' not in exclude_entity_outputs}
      { printf ',%.8g', -r_process_source_flow_d[u, source, d] / complete_period_share_of_year[d] >> fn_unit__sourceNode__d; }
  } 

printf 'Write unit__inputNode flow for time...\n';
param fn_unit__sourceNode__dt symbolic := "output/unit__inputNode__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_unit__sourceNode__dt;  # Print the header on the first solve
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, source) in process_source && u in process_unit} printf ',%s', u >> fn_unit__sourceNode__dt;
	printf '\n,,' >> fn_unit__sourceNode__dt;
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, source) in process_source && u in process_unit} printf ',%s', source >> fn_unit__sourceNode__dt;
  }
for {s in solve_current: 'output_unit__node_flow_t' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_unit__sourceNode__dt;
    for {(u, source, sink) in process_source_sink_alwaysProcess : (u, source) in process_source && u in process_unit}
      { printf ',%.8g', -r_process__source__sink_Flow__dt[u, source, sink, d, t] >> fn_unit__sourceNode__dt; }
  }} 

printf 'Write connection flow for periods...\n';
param fn_connection__d symbolic := "output/connection__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period' > fn_connection__d;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection__d;
	printf '\n,' >> fn_connection__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection__d;
	printf '\n,' >> fn_connection__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection__d;
  }
for {s in solve_current, d in d_realized_period: 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_connection__d;
    for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink}
	  { printf ',%.8g', r_connection_d[c, d] / complete_period_share_of_year[d] >> fn_connection__d; }
  }

printf 'Write connection flow for time...\n';
param fn_connection__dt symbolic := "output/connection__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_connection__dt;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection__dt;
	printf '\n,,' >> fn_connection__dt;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection__dt;
	printf '\n,,' >> fn_connection__dt;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection__dt;
  }
for {s in solve_current: 'output_connection__node__node_flow_t' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for{(d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_connection__dt;
    for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink}
	  { printf ',%.8g', r_connection_dt[c, d, t] >> fn_connection__dt; }
  }}

printf 'Write connection flow to right node for periods...\n';
param fn_connection_to_right_node__d symbolic := "output/connection_left_to_right__period.csv";
for {i in 1..1 : p_model['solveFirst'] && 'output_connection_flow_separate' in enable_optional_outputs}
  { printf 'solve,period' > fn_connection_to_right_node__d;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection_to_right_node__d;
	printf '\n,' >> fn_connection_to_right_node__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection_to_right_node__d;
	printf '\n,' >> fn_connection_to_right_node__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection_to_right_node__d;
  }
for {s in solve_current, d in d_realized_period: 'output_connection_flow_separate' in enable_optional_outputs && 'yes' not in exclude_entity_outputs }
  {
	printf '\n%s,%s', s, d >> fn_connection_to_right_node__d;
    for {c in process_connection}
	  { printf ',%.8g', r_connection_to_right_node__d[c, d] / complete_period_share_of_year[d] >> fn_connection_to_right_node__d; }
  }

printf 'Write connection flow to right node for time...\n';
param fn_connection_to_right_node__dt symbolic := "output/connection_left_to_right__period__t.csv";
for {i in 1..1 : p_model['solveFirst'] && 'output_connection_flow_separate' in enable_optional_outputs}
  { printf 'solve,period,time' > fn_connection_to_right_node__dt;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection_to_right_node__dt;
	printf '\n,,' >> fn_connection_to_right_node__dt;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection_to_right_node__dt;
	printf '\n,,' >> fn_connection_to_right_node__dt;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection_to_right_node__dt;
  }
for {s in solve_current : 'output_connection_flow_separate' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_connection_to_right_node__dt;
    for {c in process_connection}
	  { printf ',%.8g', r_connection_to_right_node__dt[c, d, t] >> fn_connection_to_right_node__dt; }
  }}

printf 'Write connection flow to left node for periods...\n';
param fn_connection_to_left_node__d symbolic := "output/connection_right_to_left__period.csv";
for {i in 1..1 : p_model['solveFirst'] && 'output_connection_flow_separate' in enable_optional_outputs}
  { printf 'solve,period' > fn_connection_to_left_node__d;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection_to_left_node__d;
	printf '\n,' >> fn_connection_to_left_node__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection_to_left_node__d;
	printf '\n,' >> fn_connection_to_left_node__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection_to_left_node__d;
  }
for {s in solve_current, d in d_realized_period: 'output_connection_flow_separate' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_connection_to_left_node__d;
    for {c in process_connection}
	  { printf ',%.8g', r_connection_to_left_node__d[c, d] / complete_period_share_of_year[d] >> fn_connection_to_left_node__d; }
  }

printf 'Write connection flow to left node for time...\n';
param fn_connection_to_left_node__dt symbolic := "output/connection_right_to_left__period__t.csv";
for {i in 1..1 : p_model['solveFirst'] && 'output_connection_flow_separate' in enable_optional_outputs}
  { printf 'solve,period,time' > fn_connection_to_left_node__dt;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection_to_left_node__dt;
	printf '\n,,' >> fn_connection_to_left_node__dt;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection_to_left_node__dt;
	printf '\n,,' >> fn_connection_to_left_node__dt;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection_to_left_node__dt;
  }
for {s in solve_current: 'output_connection_flow_separate' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_connection_to_left_node__dt;
    for {c in process_connection}
	  { printf ',%.8g', r_connection_to_left_node__dt[c, d, t] >> fn_connection_to_left_node__dt; }
  }}

printf 'Write group_output flows for time...\n';
param fn_group_flows__dt symbolic := "output/group_flows__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_group_flows__dt;  # Print the header on the first solve
	for{g in groupOutputNodeFlows}
	  {
        printf ',%s', g >> fn_group_flows__dt;
        for{(g, ga) in group_output__group_aggregate_Unit_to_group} { printf ',%s', g >> fn_group_flows__dt;}
	    for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate} { printf ',%s', g >> fn_group_flows__dt;}
        for{(g, ga) in group_output__group_aggregate_Connection} {printf ',%s', g >> fn_group_flows__dt;}
        for{(g, c) in group_output__connection_Not_in_aggregate} {printf ',%s', g >> fn_group_flows__dt;}
        for{(g, n) in group_node: n in nodeState} {printf ',%s', g >> fn_group_flows__dt;}
        for{(g, ga) in group_output__group_aggregate_Group_to_unit} {printf ',%s', g >> fn_group_flows__dt;}
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} {printf ',%s', g >> fn_group_flows__dt;}
        printf ',%s,%s,%s,%s,%s', g, g, g, g, g >> fn_group_flows__dt;
	  }
	printf '\n,,' >> fn_group_flows__dt;
	for{g in groupOutputNodeFlows}
	  {
        printf ',slack' >> fn_group_flows__dt;
        for{(g, ga) in group_output__group_aggregate_Unit_to_group} { printf ',unit_aggregate' >> fn_group_flows__dt;}
	    for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate} { printf ',unit' >> fn_group_flows__dt;}
        for{(g, ga) in group_output__group_aggregate_Connection} {printf ',connection' >> fn_group_flows__dt;}
        for{(g, c) in group_output__connection_Not_in_aggregate} {printf ',connection' >> fn_group_flows__dt;}
        for{(g, n) in group_node: n in nodeState} {printf ',storage_flow' >> fn_group_flows__dt;}
        for{(g, ga) in group_output__group_aggregate_Group_to_unit} {printf ',unit_aggregate' >> fn_group_flows__dt;}
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} {printf ',unit' >> fn_group_flows__dt;}
        printf ',internal_losses,internal_losses,internal_losses,slack,inflow' >> fn_group_flows__dt;
	  }
	printf '\n,,' >> fn_group_flows__dt;
	for{g in groupOutputNodeFlows}
	  {
        printf ',upward' >> fn_group_flows__dt;
        for{(g, ga) in group_output__group_aggregate_Unit_to_group} { printf ',%s', ga >> fn_group_flows__dt;}
	    for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate} { printf ',%s', u >> fn_group_flows__dt;}
        for{(g, ga) in group_output__group_aggregate_Connection} {printf ',%s', ga >> fn_group_flows__dt;}
        for{(g, c) in group_output__connection_Not_in_aggregate} {printf ',%s', c >> fn_group_flows__dt;}
        for{(g, n) in group_node: n in nodeState} {printf ',%s', g >> fn_group_flows__dt;}
        for{(g, ga) in group_output__group_aggregate_Group_to_unit} {printf ',%s', ga >> fn_group_flows__dt;}
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} {printf ',%s', u >> fn_group_flows__dt;}
        printf ',connections,units,storages,downward,%s', g >> fn_group_flows__dt;
	  }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_group_flows__dt;
	for {g in groupOutputNodeFlows}
	  {
        printf ',%.8g', + r_group_node_up_penalties__dt[g, d, t] >> fn_group_flows__dt;
		for{(g, ga) in group_output__group_aggregate_Unit_to_group}
			printf ',%.8g', + r_group_output__group_aggregate_Unit_to_group__dt[g, ga, d, t] >> fn_group_flows__dt;
		for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate}
		    printf ',%.8g', + r_process__source__sink_Flow__dt[u, source, sink, d, t] >> fn_group_flows__dt;
	    for{(g, ga) in group_output__group_aggregate_Connection}
            printf ',%.8g', + r_group_output__group_aggregate_Connection__dt[g, ga, d, t] >> fn_group_flows__dt;
        for{(g, c) in group_output__connection_Not_in_aggregate}
            printf ',%.8g', + r_group_output__connection_Not_in_aggregate__dt[g, c, d, t] >> fn_group_flows__dt;
        for{(g, n) in group_node: n in nodeState}
            printf ',%.8g', - r_nodeState_change_dt[n, d, t] >> fn_group_flows__dt;
        for{(g, ga) in group_output__group_aggregate_Group_to_unit}
            printf ',%.8g', + r_group_output__group_aggregate_Group_to_unit__dt[g, ga, d, t] >> fn_group_flows__dt;
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} 
            printf ',%.8g', - r_process__source__sink_Flow__dt[u, source, sink, d, t] >> fn_group_flows__dt;
        printf ',%.8g,%.8g,%.8g,%.8g,%.8g', 
		  - r_group_output_Internal_connection_losses__dt[g, d, t],
          - r_group_output_Internal_unit_losses__dt[g, d, t],
          - r_group_node_state_losses__dt[g, d, t],
          + r_group_node_down_penalties__dt[g, d, t],
          + r_group_node_inflow__dt[g, d, t] >> fn_group_flows__dt;
      } 
  }

printf 'Write annualized group_output flows for periods...\n';
param fn_group_flows__d symbolic := "output/group_flows__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period' > fn_group_flows__d;  # Print the header on the first solve
	for{g in groupOutputNodeFlows}
	  {
        printf ',%s', g >> fn_group_flows__d;
        for{(g, ga) in group_output__group_aggregate_Unit_to_group} { printf ',%s', g >> fn_group_flows__d;}
	    for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate} { printf ',%s', g >> fn_group_flows__d;}
        for{(g, ga) in group_output__group_aggregate_Connection} {printf ',%s', g >> fn_group_flows__d;}
        for{(g, c) in group_output__connection_Not_in_aggregate} {printf ',%s', g >> fn_group_flows__d;}
        for{(g, n) in group_node: n in nodeState} {printf ',%s', g >> fn_group_flows__d;}
        for{(g, ga) in group_output__group_aggregate_Group_to_unit} {printf ',%s', g >> fn_group_flows__d;}
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} {printf ',%s', g >> fn_group_flows__d;}
        printf ',%s,%s,%s,%s,%s', g, g, g, g, g >> fn_group_flows__d;
	  }
	printf '\n,' >> fn_group_flows__d;
	for{g in groupOutputNodeFlows}
	  {
        printf ',slack' >> fn_group_flows__d;
        for{(g, ga) in group_output__group_aggregate_Unit_to_group} { printf ',unit_aggregate' >> fn_group_flows__d;}
	    for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate} { printf ',unit' >> fn_group_flows__d;}
        for{(g, ga) in group_output__group_aggregate_Connection} {printf ',connection' >> fn_group_flows__d;}
        for{(g, c) in group_output__connection_Not_in_aggregate} {printf ',connection' >> fn_group_flows__d;}
        for{(g, n) in group_node: n in nodeState} {printf ',storage_flow' >> fn_group_flows__d;}
        for{(g, ga) in group_output__group_aggregate_Group_to_unit} {printf ',unit_aggregate' >> fn_group_flows__d;}
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} {printf ',unit' >> fn_group_flows__d;}
        printf ',internal_losses,internal_losses,internal_losses,slack,inflow' >> fn_group_flows__d;
	  }
	printf '\n,' >> fn_group_flows__d;
	for{g in groupOutputNodeFlows}
	  {
        printf ',upward' >> fn_group_flows__d;
        for{(g, ga) in group_output__group_aggregate_Unit_to_group} { printf ',%s', ga >> fn_group_flows__d;}
	    for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate} { printf ',%s', u >> fn_group_flows__d;}
        for{(g, ga) in group_output__group_aggregate_Connection} {printf ',%s', ga >> fn_group_flows__d;}
        for{(g, c) in group_output__connection_Not_in_aggregate} {printf ',%s', c >> fn_group_flows__d;}
        for{(g, n) in group_node: n in nodeState} {printf ',%s', g >> fn_group_flows__d;}
        for{(g, ga) in group_output__group_aggregate_Group_to_unit} {printf ',%s', ga >> fn_group_flows__d;}
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} {printf ',%s', u >> fn_group_flows__d;}
        printf ',connections,units,storages,downward,%s', g >> fn_group_flows__d;
	  }
  }
for {s in solve_current, d in d_realized_period}
  {
    printf '\n%s,%s', s, d >> fn_group_flows__d;
	for {g in groupOutputNodeFlows}
	  {
        printf ',%.8g', + r_group_node_up_penalties__d[g, d] >> fn_group_flows__d;
		for{(g, ga) in group_output__group_aggregate_Unit_to_group}
			printf ',%.8g', + r_group_output__group_aggregate_Unit_to_group__d[g, ga, d] >> fn_group_flows__d;
		for{(g, u, source, sink) in group_output__process__unit__to_node_not_in_aggregate}
		    printf ',%.8g', + r_process__source__sink_Flow__d[u, source, sink, d] >> fn_group_flows__d;
	    for{(g, ga) in group_output__group_aggregate_Connection}
            printf ',%.8g', + r_group_output__group_aggregate_Connection__d[g, ga, d] >> fn_group_flows__d;
        for{(g, c) in group_output__connection_Not_in_aggregate}
            printf ',%.8g', + r_group_output__connection_Not_in_aggregate__d[g, c, d] >> fn_group_flows__d;
        for{(g, n) in group_node: n in nodeState}
            printf ',%.8g', - r_nodeState_change_d[n, d] >> fn_group_flows__d;
        for{(g, ga) in group_output__group_aggregate_Group_to_unit}
            printf ',%.8g', + r_group_output__group_aggregate_Group_to_unit__d[g, ga, d] >> fn_group_flows__d;
        for{(g, u, source, sink) in group_output__process__node__to_unit_not_in_aggregate} 
            printf ',%.8g', - r_process__source__sink_Flow__d[u, source, sink, d] >> fn_group_flows__d;
        printf ',%.8g,%.8g,%.8g,%.8g,%.8g', 
		  - r_group_output_Internal_connection_losses__d[g, d],
          - r_group_output_Internal_unit_losses__d[g, d],
          - r_group_node_state_losses__d[g, d],
          + r_group_node_down_penalties__d[g, d],
          + r_group_node_inflow__d[g, d] >> fn_group_flows__d;
      } 
  }

param w_flow := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time;
display w_flow;

printf 'Write unit__outputNode capacity factors for periods...\n';
param fn_unit__sinkNode__d_cf symbolic := "output/unit_cf__outputNode__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'solve,period' > fn_unit__sinkNode__d_cf;  # Print the header on the first solve
	for {(u, sink) in process_sink : u in process_unit} printf ',%s', u >> fn_unit__sinkNode__d_cf;
	printf '\n,' >> fn_unit__sinkNode__d_cf;
	for {(u, sink) in process_sink : u in process_unit} printf ',%s', sink >> fn_unit__sinkNode__d_cf;
  }
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_unit__sinkNode__d_cf;
    for {(u, sink) in process_sink : u in process_unit}
      { printf ',%.6f', ( if entity_all_capacity[u, d] 
					      then r_process_sink_flow_d[u, sink, d] / complete_hours_in_period[d] / entity_all_capacity[u, d]
						  else 0 ) >> fn_unit__sinkNode__d_cf; }
  } 

printf 'Write unit__inputNode capacity factors for periods...\n';
param fn_unit__sourceNode__d_cf symbolic := "output/unit_cf__inputNode__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period' > fn_unit__sourceNode__d_cf;  # Print the header on the first solve
	for {(u, source) in process_source : u in process_unit} printf ',%s', u >> fn_unit__sourceNode__d_cf;
	printf '\n,' >> fn_unit__sourceNode__d_cf;
	for {(u, source) in process_source : u in process_unit} printf ',%s', source >> fn_unit__sourceNode__d_cf;
  }
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d	 >> fn_unit__sourceNode__d_cf;
    for {(u, source) in process_source : u in process_unit}
      { printf ',%.6f', ( if entity_all_capacity[u, d] 
	                      then r_process_source_flow_d[u, source, d] / complete_hours_in_period[d] / entity_all_capacity[u, d]
 						  else 0 ) >> fn_unit__sourceNode__d_cf; }
  } 

printf 'Write connection capacity factor for periods...\n';
param fn_connection_cf__d symbolic := "output/connection_cf__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period' > fn_connection_cf__d;  # Print the header on the first solve
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', c >> fn_connection_cf__d;
	printf '\n,' >> fn_connection_cf__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', input >> fn_connection_cf__d;
	printf '\n,' >> fn_connection_cf__d;
	for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink} printf ',%s', output >> fn_connection_cf__d;
  }
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_connection_cf__d;
    for {(c, input, output) in process_source_sink : c in process_connection && (c, output) in process_sink}
	  { printf ',%.6f', sum{(d, t) in dt_realize_dispatch} ( if entity_all_capacity[c, d] 
	                                        then ( abs(r_connection_dt[c, d, t]) 
	                                               / complete_hours_in_period[d] 
											       / entity_all_capacity[c, d] )
										    else 0 ) >> fn_connection_cf__d; }
  }
		
param w_cf := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow;
display w_cf;

printf 'Write unit__outputNode curtailment share of VRE units for periods...\n';
param fn_unit__sinkNode__d_curtailment symbolic := "output/unit_curtailment_share__outputNode__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'type,solve,period' > fn_unit__sinkNode__d_curtailment;  # Print the header on the first solve
	for {(u, sink) in process_sink : u in process_VRE} printf ',%s', u >> fn_unit__sinkNode__d_curtailment;
	printf '\n,,' >> fn_unit__sinkNode__d_curtailment;
	for {(u, sink) in process_sink : u in process_VRE} printf ',%s', sink >> fn_unit__sinkNode__d_curtailment;
  }
for {s in solve_current, d in d_realized_period: 'yes' not in exclude_entity_outputs}
  {
	  printf '\n%s,%s,%s','curtailment', s, d >> fn_unit__sinkNode__d_curtailment;
    for {(u, sink) in process_sink : u in process_VRE}
      { printf ',%.6f', ( if entity_all_capacity[u, d] && potentialVREgen[u, sink, d]
					      then ( potentialVREgen[u, sink, d] - r_process_sink_flow_d[u, sink, d] ) / potentialVREgen[u, sink, d]
						  else 0 ) >> fn_unit__sinkNode__d_curtailment; }
    printf '\n%s,%s,%s','potential', s, d >> fn_unit__sinkNode__d_curtailment;
    for {(u, sink) in process_sink : u in process_VRE}
      { printf ',%.6f', ( if entity_all_capacity[u, d] then potentialVREgen[u, sink, d] else 0 ) >> fn_unit__sinkNode__d_curtailment; }
  } 
printf 'Write unit__outputNode curtailment share of VRE units for periods...\n';
param fn_unit__sinkNode__share__dt_curtailment symbolic := "output/unit_curtailment_share__outputNode__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { 
    printf 'type,solve,period,time' > fn_unit__sinkNode__share__dt_curtailment;  # Print the header on the first solve
	for {(u, sink) in process_sink : u in process_VRE} printf ',%s', u >> fn_unit__sinkNode__share__dt_curtailment;
	printf '\n,,,' >> fn_unit__sinkNode__share__dt_curtailment;
	for {(u, sink) in process_sink : u in process_VRE} printf ',%s', sink >> fn_unit__sinkNode__share__dt_curtailment;
  }
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
    for {(d,t) in dt_realize_dispatch }
    {
    printf '\n%s,%s,%s,%s','curtailment', s, d, t >> fn_unit__sinkNode__share__dt_curtailment;
      for {(u, sink) in process_sink : u in process_VRE}
        { printf ',%.6f',( if entity_all_capacity[u, d] then ( potentialVREgen[u, sink, d] - r_process_sink_flow_d[u, sink, d]) else 0 ) >> fn_unit__sinkNode__share__dt_curtailment; }
    }
    for {(d,t) in dt_realize_dispatch } 
      {
      printf '\n%s,%s,%s,%s','potential', s, d, t >> fn_unit__sinkNode__share__dt_curtailment;
        for {(u, sink) in process_sink : u in process_VRE}
          { printf ',%.6f',( if entity_all_capacity[u, d] then ( potentialVREgen[u, sink, d]) else 0 ) >> fn_unit__sinkNode__share__dt_curtailment; }
      } 
  }
printf 'Write unit__outputNode curtailment of VRE units for time...\n';
param fn_unit__sinkNode__dt_curtailment symbolic := "output/unit_curtailment__outputNode__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_unit__sinkNode__dt_curtailment;  # Print the header on the first solve
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_VRE} printf ',%s', u >> fn_unit__sinkNode__dt_curtailment;
	printf '\n,,' >> fn_unit__sinkNode__dt_curtailment;
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_VRE} printf ',%s', sink >> fn_unit__sinkNode__dt_curtailment;
  }
for {s in solve_current : 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_unit__sinkNode__dt_curtailment;
    for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_VRE}
      { printf ',%.6f', potentialVREgen_dt[u, sink, d, t] - r_process__source__sink_Flow__dt[u, source, sink, d, t] >> fn_unit__sinkNode__dt_curtailment; }
  }} 
  
param w_curtailment := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf;
display w_curtailment;

printf 'Write ramps from units over time...\n';
param fn_unit_ramp__sinkNode__dt symbolic := "output/unit_ramp__outputNode__dt.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_unit_ramp__sinkNode__dt;  # Print the header on the first solve
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_unit} printf ',%s', u >> fn_unit_ramp__sinkNode__dt;
	printf '\n,,' >> fn_unit_ramp__sinkNode__dt;
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_unit} printf ',%s', sink >> fn_unit_ramp__sinkNode__dt;
  }
for {s in solve_current: 'output_unit__node_ramp_t' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {(d, t, t_previous) in dtt : (d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_unit_ramp__sinkNode__dt;
	  for {(u, source, sink) in process_source_sink_alwaysProcess : (u, sink) in process_sink && u in process_unit}
      { printf ',%.8g', r_process_source_sink_ramp_dtt[u, source, sink, d, t, t_previous] >> fn_unit_ramp__sinkNode__dt; }
  }} 

param fn_unit_ramp__sourceNode__dt symbolic := "output/unit_ramp__inputNode__dt.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_unit_ramp__sourceNode__dt;  # Print the header on the first solve
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, source) in process_source && u in process_unit} printf ',%s', u >> fn_unit_ramp__sourceNode__dt;
	printf '\n,,' >> fn_unit_ramp__sourceNode__dt;
	for {(u, source, sink) in process_source_sink_alwaysProcess : (u, source) in process_source && u in process_unit} printf ',%s', source >> fn_unit_ramp__sourceNode__dt;
  }
for {s in solve_current: 'output_unit__node_ramp_t' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {(d, t, t_previous) in dtt : (d, t) in dt_realize_dispatch}
	{ printf '\n%s,%s,%s', s, d, t >> fn_unit_ramp__sourceNode__dt;
	  for {(u, source, sink) in process_source_sink_alwaysProcess : (u, source) in process_source && u in process_unit}
      { printf ',%.8g', r_process_source_sink_ramp_dtt[u, source, sink, d, t, t_previous] >> fn_unit_ramp__sourceNode__dt; }
  }} 

param w_ramps := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment;
display w_ramps;

printf 'Write reserve from processes over time...\n';
param fn_process__reserve__upDown__node__dt symbolic := "output/process__reserve__upDown__node__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_process__reserve__upDown__node__dt;   # Print the header on the first solve
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', (if p in process_unit then "unit__reserve__upDown__node" else "connection__reserve__upDown__node") >> fn_process__reserve__upDown__node__dt;
	printf '\n,,' >> fn_process__reserve__upDown__node__dt;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', (if p in process_unit then "unit" else "connection") >> fn_process__reserve__upDown__node__dt;
	printf '\n,,' >> fn_process__reserve__upDown__node__dt;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', p >> fn_process__reserve__upDown__node__dt;
	printf '\n,,' >> fn_process__reserve__upDown__node__dt;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', r >> fn_process__reserve__upDown__node__dt;
	printf '\n,,' >> fn_process__reserve__upDown__node__dt;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', ud >> fn_process__reserve__upDown__node__dt;
	printf '\n,,' >> fn_process__reserve__upDown__node__dt;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', n >> fn_process__reserve__upDown__node__dt;
  }
for {s in solve_current, (d, t) in dt_realize_dispatch : 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s,%s', s, d, t >> fn_process__reserve__upDown__node__dt;
	for {(p, r, ud, n) in process_reserve_upDown_node_active}
	  { printf ',%.8g', v_reserve[p, r, ud, n, d, t].val * p_entity_unitsize[p] >> fn_process__reserve__upDown__node__dt; }
  }

printf 'Write average reserve from processes during periods...\n';
param fn_process__reserve__upDown__node__d symbolic := "output/process__reserve__upDown__node__period_average.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period' > fn_process__reserve__upDown__node__d;   # Print the header on the first solve
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', (if p in process_unit then "unit__reserve__upDown__node" else "connection__reserve__upDown__node") >> fn_process__reserve__upDown__node__d;
	printf '\n,' >> fn_process__reserve__upDown__node__d;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', (if p in process_unit then "unit" else "connection") >> fn_process__reserve__upDown__node__d;
	printf '\n,' >> fn_process__reserve__upDown__node__d;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', p >> fn_process__reserve__upDown__node__d;
	printf '\n,' >> fn_process__reserve__upDown__node__d;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', r >> fn_process__reserve__upDown__node__d;
	printf '\n,' >> fn_process__reserve__upDown__node__d;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', ud >> fn_process__reserve__upDown__node__d;
	printf '\n,' >> fn_process__reserve__upDown__node__d;
    for  {(p, r, ud, n) in process_reserve_upDown_node_active} printf ',%s', n >> fn_process__reserve__upDown__node__d;
  }
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
	printf '\n%s,%s', s, d >> fn_process__reserve__upDown__node__d;
	for {(p, r, ud, n) in process_reserve_upDown_node_active}
	  { printf ',%.8g', sum{(d, t) in dt_realize_dispatch} (v_reserve[p, r, ud, n, d, t].val * p_entity_unitsize[p] * step_duration[d, t]) / complete_hours_in_period[d] >> fn_process__reserve__upDown__node__d; }
  }

param w_reserves := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps;
display w_reserves;

printf 'Write online status of units over time...\n';
param fn_unit_online__dt symbolic := "output/unit_online__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_unit_online__dt; 
    for {p in process_unit  : p in process_online}
      { printf ',%s', p >> fn_unit_online__dt; }
  }  # Print the header on the first solve
for {s in solve_current : 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
    { printf '\n%s,%s,%s', s, d, t >> fn_unit_online__dt;
      for {p in process_unit : p in process_online}
        {
          printf ',%.8g', r_process_Online__dt[p, d, t] >> fn_unit_online__dt;
        }
  }}

printf 'Write average unit online during periods...\n';
param fn_unit_online__d symbolic := "output/unit_online__period_average.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period' > fn_unit_online__d; 
    for {p in process_unit  : p in process_online}
      { printf ',%s', p >> fn_unit_online__d; }
  }  # Print the header on the first solve
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
    printf '\n%s,%s', s, d >> fn_unit_online__d;
	for {p in process_unit : p in process_online}
	  {
	    printf ',%.8g', sum{(d, t) in dt_realize_dispatch} (r_process_Online__dt[p, d, t] * step_duration[d, t]) / complete_hours_in_period[d] >> fn_unit_online__d;
	  }
  }

printf 'Write unit startups for periods...\n';
param fn_unit_startup__d symbolic := "output/unit_startup__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period' > fn_unit_startup__d; 
    for {p in process_unit  : p in process_online}
      { printf ',%s', p >> fn_unit_startup__d; }
  }  # Print the header on the first solve
for {s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
    printf '\n%s,%s', s, d >> fn_unit_startup__d;
	for {p in process_unit : p in process_online}
	  {
	    printf ',%.8g', sum{(d, t) in dt_realize_dispatch} r_process_startup_dt[p, d, t] >> fn_unit_startup__d;
	  }
  }

param w_online := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves;
display w_online;
 
printf 'Write node results for periods...\n';
param fn_node__d symbolic := "output/node__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'node,solve,period,inflow,"from units","from connections","to units","to connections",' > fn_node__d;
    printf '"state change","self discharge","upward slack","downward slack"\n' >> fn_node__d; }  # Print the header on the first solve
for {n in node, s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
    printf '%s,%s,%s,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g\n'
		, n, s, d
        , (if (n, 'no_inflow') not in node__inflow_method && n in (nodeBalance union nodeBalancePeriod) then pdNodeInflow[n, d])
	    , sum{(p, source, n) in process_source_sink_alwaysProcess : p in process_unit} r_process_source_sink_flow_d[p, source, n, d]
	    , sum{(p, source, n) in process_source_sink_alwaysProcess : p in process_connection} r_process_source_sink_flow_d[p, source, n, d]
  	    , sum{(p, n, sink) in process_source_sink_alwaysProcess : p in process_unit} -r_process_source_sink_flow_d[p, n, sink, d]
  	    , sum{(p, n, sink) in process_source_sink_alwaysProcess : p in process_connection} -r_process_source_sink_flow_d[p, n, sink, d]
	    , (if n in nodeState then r_nodeState_change_d[n, d] else 0)
        , (if n in nodeSelfDischarge then r_selfDischargeLoss_d[n, d] else 0)
	    , sum{ud in upDown : ud = 'up' && n in nodeBalance union nodeBalancePeriod} r_penalty_nodeState_upDown_d[n, ud, d]
	    , sum{ud in upDown : ud = 'down' && n in nodeBalance union nodeBalancePeriod} -r_penalty_nodeState_upDown_d[n, ud, d]
	  >> fn_node__d;
  }

printf 'Write process CO2 results for periods...\n';
param fn_process_co2__d symbolic := "output/process__period_co2.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'class,process,solve,period,"CO2 [Mt/a]"\n' > fn_process_co2__d; }  # Print the header on the first solve 
for {p in process_co2, s in solve_current, d in d_realized_period : 'yes' not in exclude_entity_outputs}
  {
    printf '%s,%s,%s,%s,%.8g\n'
		, (if p in process_unit then "unit" else "connection"), p, s, d
        , sum{(p, c, n) in process__commodity__node_co2} r_process_emissions_co2_d[p, c, n, d]
	  >> fn_process_co2__d;
  }

printf 'Write node results for time...\n';
param fn_node__dt symbolic := "output/node__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'node,solve,period,time,inflow,"from units","from connections","to units","to connections",' > fn_node__dt;
    printf '"state change","self discharge","upward slack","downward slack"\n' >> fn_node__dt; }  # Print the header on the first solve
for {s in solve_current: 'output_node_balance_t' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for {n in node, (d, t) in dt_realize_dispatch}
    { printf '%s,%s,%s,%s,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g,%.8g\n'
      , n, s, d, t
          , + (if (n, 'no_inflow') not in node__inflow_method && n in nodeBalance union nodeBalancePeriod then pdtNodeInflow[n, d, t])
        , sum{(p, source, n) in process_source_sink_alwaysProcess : p in process_unit} r_process__source__sink_Flow__dt[p, source, n, d, t]
        , sum{(p, source, n) in process_source_sink_alwaysProcess : p in process_connection} r_process__source__sink_Flow__dt[p, source, n, d, t]
          , sum{(p, n, sink) in process_source_sink_alwaysProcess : p in process_unit} -r_process__source__sink_Flow__dt[p, n, sink, d, t]
          , sum{(p, n, sink) in process_source_sink_alwaysProcess : p in process_connection} -r_process__source__sink_Flow__dt[p, n, sink, d, t]
        , (if n in nodeState then r_nodeState_change_dt[n, d, t] else 0)
          , (if n in nodeSelfDischarge then r_selfDischargeLoss_dt[n, d, t] else 0)
        , (if n in (nodeBalance union nodeBalancePeriod) then vq_state_up[n, d, t].val * node_capacity_for_scaling[n, d] else 0)
        , (if n in (nodeBalance union nodeBalancePeriod) then -vq_state_down[n, d, t].val * node_capacity_for_scaling[n, d] else 0)
      >> fn_node__dt;
  }}

printf 'Write nodal prices for time...\n';
param fn_nodal_prices__dt symbolic := "output/node_prices__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  {
    printf 'solve,period,time' > fn_nodal_prices__dt;
    for {n in nodeBalance}
      { printf ',%s', n >> fn_nodal_prices__dt; }
  }
for {s in solve_current: 'yes' not in exclude_entity_outputs}
  { for {(d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt : (d, t) in dt_realize_dispatch}
    { printf '\n%s,%s,%s', s, d, t >> fn_nodal_prices__dt;
      for {c in solve_current, n in nodeBalance}
      {
        printf ',%8g', -nodeBalance_eq[c, n, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve].dual / p_discount_factor_operations_yearly[d]  / scale_the_objective >> fn_nodal_prices__dt;
        }
  }}

printf 'Write node state for time..\n';
param fn_nodeState__dt symbolic := "output/node_state__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_nodeState__dt;
    for {n in nodeState}
      { printf ',%s', n >> fn_nodeState__dt; }
  }
for {s in solve_current : 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
    { printf '\n%s,%s,%s', s, d, t >> fn_nodeState__dt;
      for {n in nodeState} 
        {
        printf ',%.8g', v_state[n, d, t].val * p_entity_unitsize[n] >> fn_nodeState__dt;
        }
  }}

printf 'Write node upward slack over time..\n';
param fn_node_upward_slack__dt symbolic := "output/slack__upward__node_state__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_node_upward_slack__dt;
    for {n in nodeBalance union nodeBalancePeriod}
      { printf ',%s', n >> fn_node_upward_slack__dt; }
  }
for {s in solve_current : 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
    { printf '\n%s,%s,%s', s, d, t >> fn_node_upward_slack__dt;
      for {n in (nodeBalance union nodeBalancePeriod)} 
        {
        printf ',%.8g', vq_state_up[n, d, t].val * node_capacity_for_scaling[n, d]  >> fn_node_upward_slack__dt;
        }
  }}

printf 'Write node downward slack over time..\n';
param fn_node_downward_slack__dt symbolic := "output/slack__downward__node_state__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_node_downward_slack__dt;
    for {n in nodeBalance union nodeBalancePeriod}
      { printf ',%s', n >> fn_node_downward_slack__dt; }
  }
for {s in solve_current : 'yes' not in exclude_entity_outputs}
  { for {(d, t) in dt_realize_dispatch}
    { printf '\n%s,%s,%s', s, d, t >> fn_node_downward_slack__dt;
      for {n in nodeBalance union nodeBalancePeriod} 
        {
        printf ',%.8g', vq_state_down[n, d, t].val * node_capacity_for_scaling[n, d]  >> fn_node_downward_slack__dt;
        }
  }}

printf 'Write reserve prices over time...\n';
param fn_group_reserve_price__dt symbolic := "output/reserve_price__upDown__group__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_group_reserve_price__dt; 
    for {(r, ud, g) in reserve__upDown__group}
      { printf ',%s', r >> fn_group_reserve_price__dt; }
    printf '\n,,' >> fn_group_reserve_price__dt;
    for {(r, ud, g) in reserve__upDown__group}
      { printf ',%s', ud >> fn_group_reserve_price__dt; }
    printf '\n,,' >> fn_group_reserve_price__dt;
    for {(r, ud, g) in reserve__upDown__group}
      { printf ',%s', g >> fn_group_reserve_price__dt; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_group_reserve_price__dt;
    for {(r, ud, g) in reserve__upDown__group}
      {
    for {(r, ud, g, r_m) in reserve__upDown__group__method : r_m <> 'no_reserve'}
        printf ',%.8g', ( if ud = 'up' then
		                    max(( if (r, ud, g, r_m) in reserve__upDown__group__method_timeseries then reserveBalance_timeseries_eq[r, ud, g, r_m, d, t].dual else 0 ),
							    ( if (r, ud, g, r_m) in reserve__upDown__group__method_dynamic    then reserveBalance_dynamic_eq[r, ud, g, r_m, d, t].dual else 0 ),
							    ( if (r, ud, g, r_m) in reserve__upDown__group__method_n_1        
								  then max{p_n_1 in process_large_failure : sum{(p_n_1, sink) in process_sink : (g, sink) in group_node} 1} reserveBalance_up_n_1_eq[r, g, r_m, p_n_1, d, t].dual else 0 )
							   )
						  else
		                    max(( if (r, ud, g, r_m) in reserve__upDown__group__method_timeseries then reserveBalance_timeseries_eq[r, ud, g, r_m, d, t].dual else 0 ),
							    ( if (r, ud, g, r_m) in reserve__upDown__group__method_dynamic    then reserveBalance_dynamic_eq[r, ud, g, r_m, d, t].dual else 0 ),
							    ( if (r, ud, g, r_m) in reserve__upDown__group__method_n_1        
								  then max{p_n_1 in process_large_failure : sum{(p_n_1, source) in process_source : (g, source) in group_node} 1} reserveBalance_down_n_1_eq[r, g, r_m, p_n_1, d, t].dual else 0 )
							   )
						) / p_discount_factor_operations_yearly[d] * complete_period_share_of_year[d]
		    >> fn_group_reserve_price__dt;
      }
  }

param w_node := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves - w_online;
display w_node;

printf 'Write marginal value for investment entities...\n';
param fn_unit_invested_marginal symbolic := "output/unit_invest_marginal__period.csv";
for {i in 1..1 : p_model['solveFirst']} 
  { printf 'solve,period' > fn_unit_invested_marginal;
    for {e in entityInvest : e in process_unit}
	  { printf ',%s', e >> fn_unit_invested_marginal; }
  }
for {s in solve_current, d in d_realize_invest : 'yes' not in exclude_entity_outputs}
  { printf '\n%s,%s', s, d >> fn_unit_invested_marginal;
    for {e in entityInvest : e in process_unit} 
      {
	    printf ',%.8g', (if (e, d) in ed_invest then v_invest[e, d].dual) >> fn_unit_invested_marginal;
      }
  }

param fn_connection_invested_marginal symbolic := "output/connection_invest_marginal__period.csv";
for {i in 1..1 : p_model['solveFirst']} 
  { printf 'solve,period' > fn_connection_invested_marginal;
    for {e in entityInvest : e in process_connection}
	  { printf ',%s', e >> fn_connection_invested_marginal; }
  }
for {s in solve_current, d in d_realize_invest : 'yes' not in exclude_entity_outputs}
  { printf '\n%s,%s', s, d >> fn_connection_invested_marginal;
    for {e in entityInvest : e in process_connection} 
      {
	    printf ',%.8g', (if (e, d) in ed_invest then v_invest[e, d].dual) >> fn_connection_invested_marginal;
      }
  }

param fn_node_invested_marginal symbolic := "output/node_invest_marginal__period.csv";
for {i in 1..1 : p_model['solveFirst']} 
  { printf 'solve,period' > fn_node_invested_marginal;
    for {e in entityInvest : e in node}
	  { printf ',%s', e >> fn_node_invested_marginal; }
  }
for {s in solve_current, d in d_realize_invest : 'yes' not in exclude_entity_outputs}
  { printf '\n%s,%s', s, d >> fn_node_invested_marginal;
    for {e in entityInvest : e in node} 
      {
	    printf ',%.8g', (if (e, d) in ed_invest then v_invest[e, d].dual) >> fn_node_invested_marginal;
      }
  }

param w_marginal_inv := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves - w_online - w_node;
display w_marginal_inv;

param r_node_ramproom_units_up_dtt{n in nodeBalance, (d, t, t_previous) in dtt: 'output_ramp_envelope' in enable_optional_outputs} := 
          + sum{(u, source, n) in process_source_sink_alwaysProcess : u in process_unit && u not in process_VRE} ( 
              + p_process_sink_coefficient[u, n]
                * ( if u in process_online 
			  	    then r_process_Online__dt[u, d, t] * p_entity_unitsize[u]
			  		else entity_all_capacity[u, d]
		          )
			  - r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'up'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
		  + sum{(u, n, sink) in process_source_sink_alwaysProcess : u in process_unit && u not in process_VRE} ( 
			  + r_process__source__sink_Flow__dt[u, n, sink, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'up'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			);

param r_node_ramproom_units_down_dtt{n in nodeBalance, (d, t, t_previous) in dtt: 'output_ramp_envelope' in enable_optional_outputs} := 
          - sum{(u, source, n) in process_source_sink_alwaysProcess : u in process_unit && u not in process_VRE} ( 
			  + r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
		  - sum{(u, n, sink) in process_source_sink_alwaysProcess : u in process_unit && u not in process_VRE} ( 
              + p_process_source_coefficient[u, n]
                * ( if u in process_online 
			  	    then r_process_Online__dt[u, d, t] * p_process[u, 'min_load'] * p_entity_unitsize[u]
					else entity_all_capacity[u, d]
		          )
			  - r_process__source__sink_Flow__dt[u, n, sink, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			);  

param r_node_ramproom_VRE_up_dtt{n in nodeBalance, (d, t, t_previous) in dtt: 'output_ramp_envelope' in enable_optional_outputs} := 
          + r_node_ramproom_units_up_dtt[n, d, t, t_previous]
		  + sum{(u, source, n) in process_source_sink_alwaysProcess : u in process_unit && u in process_VRE} ( 
              + p_process_sink_coefficient[u, n]
                * ( if u in process_online 
			  	    then r_process_Online__dt[u, d, t] * p_entity_unitsize[u]
			  		else entity_all_capacity[u, d]
		          )
				* sum{(u, source, n, f, 'upper_limit') in process__source__sink__profile__profile_method} pdtProfile[f, d, t]
			  - r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'up'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
		  + sum{(u, n, sink) in process_source_sink_alwaysProcess : u in process_unit && u in process_VRE} ( 
			  + r_process__source__sink_Flow__dt[u, n, sink, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'up'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			);

param r_node_ramproom_VRE_down_dtt{n in nodeBalance, (d, t, t_previous) in dtt: 'output_ramp_envelope' in enable_optional_outputs} := 
          + r_node_ramproom_units_down_dtt[n, d, t, t_previous]
          - sum{(u, source, n) in process_source_sink_alwaysProcess : u in process_unit && u in process_VRE} ( 
			  + r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
		  - sum{(u, n, sink) in process_source_sink_alwaysProcess : u in process_unit && u in process_VRE} ( 
              + p_process_source_coefficient[u, n]
                * ( if u in process_online 
			  	    then r_process_Online__dt[u, d, t] * p_process[u, 'min_load'] * p_entity_unitsize[u]
					else entity_all_capacity[u, d]
		          )
				* sum{(u, n, sink, f, 'upper_limit') in process__source__sink__profile__profile_method} pdtProfile[f, d, t]
			  - r_process__source__sink_Flow__dt[u, n, sink, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			);  

param r_node_ramproom_connections_up_dtt{n in nodeBalance, (d, t, t_previous) in dtt: 'output_ramp_envelope' in enable_optional_outputs} :=  
          + r_node_ramproom_VRE_up_dtt[n, d, t, t_previous]
          + sum{(u, source, n) in process_source_sink_alwaysProcess : (u, n) in process_sink && u in process_connection && u not in process_VRE} ( 
              + p_process_sink_coefficient[u, n]
                * ( if u in process_online 
			  	    then r_process_Online__dt[u, d, t] * p_entity_unitsize[u]
			  		else entity_all_capacity[u, d]
		          )
			  - r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'up'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
		  + sum{(u, n, sink) in process_source_sink_alwaysProcess : u in process_connection && u not in process_VRE} ( 
			  + r_process__source__sink_Flow__dt[u, n, sink, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'up'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			);

param r_node_ramproom_connections_down_dtt{n in nodeBalance, (d, t, t_previous) in dtt: 'output_ramp_envelope' in enable_optional_outputs} := 
          + r_node_ramproom_VRE_down_dtt[n, d, t, t_previous]
          - sum{(u, source, n) in process_source_sink_alwaysProcess : (u, n) in process_sink && u in process_connection && u not in process_VRE && u not in process_sinkIsNode_2way1var} ( 
			  + r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
          - sum{(u, source, n) in process_source_sink_alwaysProcess : u in process_connection && u not in process_VRE && u in process_sinkIsNode_2way1var} ( 
              + p_process_sink_coefficient[u, n]
                * ( if u in process_online 
			  	    then r_process_Online__dt[u, d, t] * p_process[u, 'min_load'] * p_entity_unitsize[u]
					else entity_all_capacity[u, d]
		          )
			  + r_process__source__sink_Flow__dt[u, source, n, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
		  - sum{(u, n, sink) in process_source_sink_alwaysProcess : (u, n) in process_source && u in process_connection && u not in process_VRE && u not in process_sinkIsNode_2way1var} ( 
              + p_process_source_coefficient[u, n]
                * ( if u in process_online
			  	    then (if u in process_online_integer then ( p_entity_existing_integer_count[u, d] 
                  + (if d in period_invest then v_invest[u, d] else 0)
                  - r_process_Online__dt[u, d, t] )
                else r_process_Online__dt[u, d, t])
               * p_process[u, 'min_load'] * p_entity_unitsize[u]
					else entity_all_capacity[u, d]
		          )
			  - r_process__source__sink_Flow__dt[u, n, sink, d, t]
			  - sum{(u, r, ud, n) in process_reserve_upDown_node_active : ud = 'down'}
				     v_reserve[u, r, ud, n, d, t].val * p_entity_unitsize[u]
			)
;  

printf 'Write node ramps for time...\n';
param fn_node_ramp__dtt symbolic := "output/node_ramp__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'node,solve,period,time,"ramp","+connections_up","+VRE_up","units_up",' > fn_node_ramp__dtt;
    printf '"units_down","+VRE_down","+connections_down"' >> fn_node_ramp__dtt; }  # Print the header on the first solve
for {s in solve_current: 'output_ramp_envelope' in enable_optional_outputs && 'yes' not in exclude_entity_outputs}
  { for{n in nodeBalance, (d, t, t_previous) in dtt : (d, t) in dt_realize_dispatch}
    { printf '\n%s,%s,%s,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f'
      , n, s, d, t
      , r_node_ramp_dtt[n, d, t, t_previous]
      , r_node_ramproom_connections_up_dtt[n, d, t, t_previous]
      , r_node_ramproom_VRE_up_dtt[n, d, t, t_previous]
          , r_node_ramproom_units_up_dtt[n, d, t, t_previous]
      , r_node_ramproom_units_down_dtt[n, d, t, t_previous]
      , r_node_ramproom_VRE_down_dtt[n, d, t, t_previous]
      , r_node_ramproom_connections_down_dtt[n, d, t, t_previous]
      >> fn_node_ramp__dtt;
  }}

param w_ramp_room := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves - w_online - w_node - w_marginal_inv;
display w_ramp_room;

printf 'Write group inertia over time...\n';
param fn_group_inertia__dt symbolic := "output/group_inertia__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_group_inertia__dt;
    for {g in groupInertia}
	  { printf ',%s', g >> fn_group_inertia__dt; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_group_inertia__dt;
	for {g in groupInertia}
	  { printf ',%.8g' 
		  , + sum {(p, source, sink) in process_source_sink : (p, source) in process_source && (g, source) in group_node && p_process_source[p, source, 'inertia_constant']} 
              ( + (if p in process_online then r_process_Online__dt[p, d, t] * p_entity_unitsize[p]) 
	            + (if p not in process_online then v_flow[p, source, sink, d, t] * p_entity_unitsize[p])
	          ) * p_process_source[p, source, 'inertia_constant']
            + sum {(p, source, sink) in process_source_sink : (p, sink) in process_sink && (g, sink) in group_node && p_process_sink[p, sink, 'inertia_constant']} 
              ( + (if p in process_online then r_process_Online__dt[p, d, t]* p_entity_unitsize[p]) 
	            + (if p not in process_online then v_flow[p, source, sink, d, t] * p_entity_unitsize[p])
              ) * p_process_sink[p, sink, 'inertia_constant']
  		  >> fn_group_inertia__dt;
	  }
  }

printf 'Write group inertia over time for individual entities...\n';
param fn_unit_inertia__dt symbolic := "output/group__unit__node_inertia__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_unit_inertia__dt;
    for {g in groupInertia}
    {
      for {(p, source, sink) in process_source_sink : (p, source) in process_source && (g, source) in group_node && p_process_source[p, source, 'inertia_constant']}
      { printf ',%s', g >> fn_unit_inertia__dt; }
      for {(p, source, sink) in process_source_sink : (p, sink) in process_sink && (g, sink) in group_node && p_process_sink[p, sink, 'inertia_constant']}
      { printf ',%s', g >> fn_unit_inertia__dt; }
    }
    printf '\n,,' >> fn_unit_inertia__dt;
    for {g in groupInertia}
    {
      for {(p, source, sink) in process_source_sink : (p, source) in process_source && (g, source) in group_node && p_process_source[p, source, 'inertia_constant']}
      { printf ',%s', p >> fn_unit_inertia__dt; }
      for {(p, source, sink) in process_source_sink : (p, sink) in process_sink && (g, sink) in group_node && p_process_sink[p, sink, 'inertia_constant']}
      { printf ',%s', p >> fn_unit_inertia__dt; }
    }
    printf '\n,,' >> fn_unit_inertia__dt;
    for {g in groupInertia}
    {
      for {(p, source, sink) in process_source_sink : (p, source) in process_source && (g, source) in group_node && p_process_source[p, source, 'inertia_constant']}
      { printf ',%s', source >> fn_unit_inertia__dt; }
      for {(p, source, sink) in process_source_sink : (p, sink) in process_sink && (g, sink) in group_node && p_process_sink[p, sink, 'inertia_constant']}
      { printf ',%s', sink >> fn_unit_inertia__dt; }
    }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_unit_inertia__dt;
	for {g in groupInertia}
    {
    for {(p, source, sink) in process_source_sink: (p, source) in process_source && (g, source) in group_node && p_process_source[p, source, 'inertia_constant']}
      { printf ',%.8g' 
        , (( + (if p in process_online then r_process_Online__dt[p, d, t] * p_entity_unitsize[p]) 
            + (if p not in process_online then v_flow[p, source, sink, d, t] * p_entity_unitsize[p])
          ) * p_process_source[p, source, 'inertia_constant'])
          >> fn_unit_inertia__dt;
      }
    for {(p, source, sink) in process_source_sink: (p, sink) in process_sink && (g, sink) in group_node && p_process_sink[p, sink, 'inertia_constant']}
        {printf ',%.8g' 
        , (( + (if p in process_online then r_process_Online__dt[p, d, t] * p_entity_unitsize[p]) 
            + (if p not in process_online then v_flow[p, source, sink, d, t] * p_entity_unitsize[p])
          ) * p_process_sink[p, sink, 'inertia_constant'])
          >> fn_unit_inertia__dt;
        }
	  }
  }

param fn_group_inertia_largest_flow__dt symbolic := "output/group_inertia_largest_flow__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_group_inertia_largest_flow__dt;
    for {g in groupInertia}
	  { printf ',%s', g >> fn_group_inertia_largest_flow__dt; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_group_inertia_largest_flow__dt;
	for {g in groupInertia}
	  { printf ',%.8g' 
		  , + max {(p, source, sink) in process_source_sink : (p, sink) in process_sink && (g, sink) in group_node} 
              ( v_flow[p, source, sink, d, t] * p_entity_unitsize[p] )
  		  >> fn_group_inertia_largest_flow__dt;
	  }
  }

param w_inertia := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves - w_online - w_node - w_marginal_inv - w_ramp_room;
display w_inertia;

printf 'Write reserve slack variables over time...\n';
param fn_group_reserve_slack__dt symbolic := "output/slack__reserve__upDown__group__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_group_reserve_slack__dt; 
    for {(r, ud, g) in reserve__upDown__group}
      { printf ',%s', r >> fn_group_reserve_slack__dt; }
    printf '\n,,' >> fn_group_reserve_slack__dt;
    for {(r, ud, g) in reserve__upDown__group}
      { printf ',%s', ud >> fn_group_reserve_slack__dt; }
    printf '\n,,' >> fn_group_reserve_slack__dt;
    for {(r, ud, g) in reserve__upDown__group}
      { printf ',%s', g >> fn_group_reserve_slack__dt; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_group_reserve_slack__dt;
    for {(r, ud, g) in reserve__upDown__group}
      {
        printf ',%.8g', vq_reserve[r, ud, g, d, t].val * pdtReserve_upDown_group[r, ud, g, 'reservation', d, t]
		    >> fn_group_reserve_slack__dt;
      }
  }

printf 'Write non-synchronous slack variables over time...\n';
param fn_group_nonsync_slack__dt symbolic := "output/slack__nonsync_group__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_group_nonsync_slack__dt; 
    for {g in groupNonSync}
      { printf ',%s', g >> fn_group_nonsync_slack__dt; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
      printf '\n%s,%s,%s', s, d, t >> fn_group_nonsync_slack__dt;
      for {g in groupNonSync}
        { 
		    printf ',%.8g', vq_non_synchronous[g, d, t].val * group_capacity_for_scaling[g, d]
		    >> fn_group_nonsync_slack__dt;
        }
  }

printf 'Write inertia slack variables over time...\n';
param fn_group_inertia_slack__dt symbolic := "output/slack__inertia_group__period__t.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period,time' > fn_group_inertia_slack__dt; 
    for {g in groupInertia}
      { printf ',%s', g >> fn_group_inertia_slack__dt; }
  }
for {s in solve_current, (d, t) in dt_realize_dispatch}
  {
    printf '\n%s,%s,%s', s, d, t >> fn_group_inertia_slack__dt;
    for {g in groupInertia}
      {
		    printf ',%.8g', vq_inertia[g, d, t].val * pdGroup[g, 'inertia_limit', d]
		    >> fn_group_inertia_slack__dt;
      }
  }

printf 'Write capacity margin slack for periods with investments...\n';
param fn_group_capmargin_slack__d symbolic := "output/slack__capacity_margin__period.csv";
for {i in 1..1 : p_model['solveFirst']}
  { printf 'solve,period' > fn_group_capmargin_slack__d; 
    for {g in groupCapacityMargin}
      { printf ',%s', g >> fn_group_capmargin_slack__d; }
  }
for {s in solve_current, d in d_realize_invest}
  {
    printf '\n%s,%s', s, d >> fn_group_capmargin_slack__d;
		for {g in groupCapacityMargin}
      {
        printf ',%.8g', vq_capacity_margin[g, d].val * group_capacity_for_scaling[g, d]
		    >> fn_group_capmargin_slack__d;
      }
  }

param w_slacks := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves - w_online - w_node - w_marginal_inv - w_ramp_room - w_inertia;
display w_slacks;

### UNIT TESTS ###
param unitTestFile symbolic := "tests/unitTests.txt";
printf (if sum{d in debug} 1 then '%s --- ' else ''), time2str(gmtime(), "%FT%TZ") > unitTestFile;
for {d in debug} {
  printf '%s  ', d >> unitTestFile;
}
printf (if sum{d in debug} 1 then '\n\n' else '') >> unitTestFile;

## Objective test
printf (if (sum{d in debug} 1 && total_cost.val / scale_the_objective <> d_obj) 
        then 'Objective value test fails. Model value: %.8g, test value: %.8g\n' else ''), total_cost.val / 1000000 / scale_the_objective , d_obj >> unitTestFile;

## Testing flows from and to node
for {n in node : 'method_1way_1var' in debug || 'mini_system' in debug} {
  printf 'Testing incoming flows of node %s\n', n >> unitTestFile;
  for {(p, source, n, d, t) in peedt} {
    printf (if v_flow[p, source, n, d, t].val * p_entity_unitsize[p] <> d_flow[p, source, n, d, t] 
	        then 'Test fails at %s, %s, %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
			    p, source, n, d, t, v_flow[p, source, n, d, t].val * p_entity_unitsize[p], d_flow[p, source, n, d, t] >> unitTestFile;
  }
  printf 'Testing outgoing flows of node %s\n', n >> unitTestFile;
  for {(p, n, sink, d, t) in peedt : sum{(p, m) in process_method : m = 'method_1var' || m = 'method_2way_2var'} 1 } {
    printf (if -v_flow[p, n, sink, d, t].val * p_entity_unitsize[p] / pdtProcess[p, 'efficiency', d, t] <> d_flow_1_or_2_variable[p, n, sink, d, t]
	        then 'Test fails at %s, %s, %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
	            p, n, sink, d, t, -v_flow[p, n, sink, d, t].val * p_entity_unitsize[p] / pdtProcess[p, 'efficiency', d, t], d_flow_1_or_2_variable[p, n, sink, d, t] >> unitTestFile;
  }
  for {(p, n, sink, d, t) in peedt : sum{(p, m) in process_method : m in method && (m <> 'method_1var' || m <> 'method_2way_2var')} 1 } {
    printf (if -v_flow[p, n, sink, d, t].val * p_entity_unitsize[p] <> d_flow[p, n, sink, d, t] 
	        then 'Test fails at %s, %s, %s, %s, %s, model value: %.8g, test value: %.8g\n' else ''),
	            p, n, sink, d, t, -v_flow[p, n, sink, d, t].val * p_entity_unitsize[p], d_flow[p, n, sink, d, t] >> unitTestFile;
  }
  printf '\n' >> unitTestFile;
}  

## Testing reserves
for {(p, r, ud, n, d, t) in prundt} {
  printf (if v_reserve[p, r, ud, n, d, t].val * p_entity_unitsize[p] <> d_reserve_upDown_node[p, r, ud, n, d, t]
          then 'Reserve test fails at %s, %s, %s, %s, %s, %s. Model value: %.8g, test value: %.8g\n' else ''),
		      p, r, ud, n, d, t, v_reserve[p, r, ud, n, d, t].val * p_entity_unitsize[p], d_reserve_upDown_node[p, r, ud, n, d, t] >> unitTestFile;
}
for {(r, ud, ng) in reserve__upDown__group, (d, t) in dt} {
  printf (if vq_reserve[r, ud, ng, d, t].val * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t] <> dq_reserve[r, ud, ng, d, t]
          then 'Reserve slack variable test fails at %s, %s, %s, %s, %s. Model value: %.8g, test value: %.8g\n' else ''),
		      r, ud, ng, d, t, vq_reserve[r, ud, ng, d, t].val * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t], dq_reserve[r, ud, ng, d, t] >> unitTestFile;
}

printf (if sum{d in debug} 1 then '\n\n' else '') >> unitTestFile;	  

param w_unit_test := gmtime() - datetime0 - setup1 - w_calc_slope - setup2 - w_total_cost - balance - reserves - indirect - rest - w_solve - w_capacity - w_group - w_costs_period - w_costs_time - w_flow - w_cf - w_curtailment - w_ramps - w_reserves - w_online - w_node - w_marginal_inv - w_ramp_room - w_inertia - w_slacks;
display w_unit_test;


param w_full := gmtime()-datetime0;
display w_full;
#display period_first;
#display period;
#display period__time_first;
#display period_last;
#display branch;
#display branch_all;
#display period__branch;
#display solve_branch__time_branch;
#display {d in period_in_use}: pd_branch_weight[d];
#display {d in period_in_use}: complete_period_share_of_year[d];
#display {p in process, (d,t) in dt}: pdtProcess_slope[p, d, t];
#display {n in nodeBalance union nodeBalancePeriod, b in branch, (b,t) in dt, (b, ts) in period__time_first}: pbt_node_inflow[n, b, ts, t];
#display {(g, n) in group_node, (d,t) in dt : g in groupStochastic}: pdtNodeInflow[n, d, t];
#display {(p,n,f,m) in process__node__profile__profile_method, (d,t) in dt}: pdtProfile[f,d,t];
#display {(p,n,p2) in process_source_sink, (d,t) in dt: n in nodeState} v_flow[p,n,p2,d,t];
#display {(p,p2,n) in process_source_sink, (d,t) in dt: n in nodeState} v_flow[p,p2,n,d,t];
#display {n in nodeState, (d,t) in dt}: v_state[n,d,t];
#display dtttdt;
#display {(p, r, ud, n, d, t) in prundt : sum{(r, ud, g) in reserve__upDown__group} 1 } : v_reserve[p, r, ud, n, d, t].dual / p_entity_unitsize[p];
#display {(p, source, sink) in process_source_sink_alwaysProcess, (d, t) in dt : (d, t) in test_dt}: r_process__source__sink_Flow__dt[p, source, sink, d, t];
#display {p in process, (d, t) in dt : (d, t) in test_dt}: r_cost_process_other_operational_cost_dt[p, d, t];
#display {(p, source, sink, d, t) in peedt : (d, t) in test_dt}: v_flow[p, source, sink, d, t].val;
#display {(p, source, sink, d, t) in peedt : (d, t) in test_dt}: v_flow[p, source, sink, d, t].dual;
#display {p in process_online, (d, t) in dt : (d, t) in test_dt} : r_process_Online__dt[p, d, t];
#display {n in nodeState, (d, t) in dt : (d, t) in test_dt}: v_state[n, d, t].val;
#display {n in nodeBalance union nodeBalancePeriod, (d, t) in dt : (d, t) in test_dt}: pdtNodeInflow[n, d, t];
#display {n in nodeBalance union nodeBalancePeriod, (d, t) in dt : (d, t) in test_dt}: pdtNode[n, 'penalty_up', d, t];
#display {n in nodeBalance union nodeBalancePeriod, (d, t) in dt : (d, t) in test_dt}: pdtNode[n, 'availability', d, t];
#display {n in nodeState, (d, t) in dt : (d, t) in test_dt}: v_state[n, d, t].val * p_entity_unitsize[n];
#display {(p, r, ud, n, d, t) in prundt : (d, t) in test_dt}: v_reserve[p, r, ud, n, d, t].val * p_entity_unitsize[p];
#display {(r, ud, ng) in reserve__upDown__group, (d, t) in test_dt}: vq_reserve[r, ud, ng, d, t].val * pdtReserve_upDown_group[r, ud, ng, 'reservation', d, t];
#display {n in (nodeBalance union nodeBalancePeriod), (d, t) in dt : (d, t) in test_dt}: vq_state_up[n, d, t].val * node_capacity_for_scaling[n, d];
#display {n in (nodeBalance union nodeBalancePeriod), (d, t) in dt : (d, t) in test_dt}: vq_state_down[n, d, t].val * node_capacity_for_scaling[n, d];
#display {g in groupInertia, (d, t) in dt : (d, t) in test_dt}: inertia_constraint[g, d, t].dual;
#display {c in current_solve, n in nodeBalance, (d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve) in dtttdt : (d, t) in test_dt}: -nodeBalance_eq[n, d, t, t_previous, t_previous_within_block, d_previous, t_previous_within_solve].dual / p_discount_factor_operations_yearly[d] * complete_period_share_of_year[d] / scale_the_objective;
#display {(r, ud, g, r_m) in reserve__upDown__group__method_timeseries, (d, t) in dt : (d, t) in test_dt}: reserveBalance_timeseries_eq[r, ud, g, r_m, d, t].dual;
#display {(p, source, sink) in process_source_sink, (d, t) in dt : (d, t) in test_dt && (p, sink) in process_sink}: maxToSink[p, source, sink, d, t].ub;
#display {(p, sink, source) in process_sink_toSource, (d, t) in dt : (d, t) in test_dt}: maxToSource[p, sink, source, d, t].ub;
#display {(p, m) in process_method, (d, t) in dt : (d, t) in test_dt && m in method_indirect} conversion_indirect[p, m, d, t].ub;
#display {(p, source, sink, f, m) in process__source__sink__profile__profile_method, (d, t) in dt : (d, t) in test_dt && m = 'lower_limit'}: profile_flow_lower_limit[p, source, sink, f, d, t].dual;
#display {(p, sink) in process_sink, param in sourceSinkTimeParam, (d, t) in test_dt}: ptProcess_sink[p, sink, param, t];
display v_invest, v_divest, solve_current, total_cost;
#display {(p, source, sink) in process_source_sink, (d, t) in test_dt}: pdtProcess__source__sink__dt_varCost[p, source, sink, d, t];
#display p_entity_all_existing;
#display test_dt;
#display {n in nodeBalancePeriod, (d, t) in dt}: vq_state_up[n, d, t].val * node_capacity_for_scaling[n, d];
#display {n in nodeBalancePeriod, (d, t) in dt}: pdtNodeInflow[n, d, t];
#display p_entity_existing_capacity_first_solve;
end;
