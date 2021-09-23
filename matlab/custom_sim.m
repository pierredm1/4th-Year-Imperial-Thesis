clear,clc
number_of_cycles = 2;
X_Train = {}
Y_Train = {}
for i= 1:number_of_cycles
    % Define the parameters structure.
    
    % the init_cell_soc is taken at random between 20% and 100%
    beginning_SOC = randi([10,90],1,1);
    param{1} = Parameters_init(beginning_SOC);
    % Change the CVs number in each battery section
    
    % Positive Current Collector
    param{1}.Nal   = 10;
    % Positive Electrode
    param{1}.Np    = 30;
    % Separator
    param{1}.Ns    = 30;
    % Negative Electrode
    param{1}.Nn    = 30;
    % Negative Current Collector
    param{1}.Nco   = 10;

    % Note that length(timings)==length(input_currents) !!

    % Initialize the states and their time derivatives
    initialState.Y      = [];
    initialState.YP     = [];
    

    %1C rate in current density
    OneC_density = 29.23;
    
    %For discharage rates up to 10C, must used Ficks law for accuracy
    %only valid up to 5C - using 6C so will leave

   % create array of currents 
   
    meanDist = -8.4295;
    stdDist = 21.6473;
    dist = makedist('Normal','mu',-8.4295,'sigma',21.6473)
    distT = truncate(dist,-6*OneC_density,3*OneC_density)
    input_currents = [];
    
    for j = 1:100
        input_currents(end+1,1) = random(distT)
    end

    %len is number of time intervals
    len = length(input_currents);
%     intervals from 0.5s to 5s
%     intervalsarray = [1,2,3,4,5];
    intervalsarray = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];
    timeinterval = [];
    for l=1:len
        index = randperm(10,1);
        timeinterval(1,end+1) = intervalsarray(1, index);
    end

    % Set the initial integration time
    t0 	= 0;
    tf  = 0;
    % Initialize the array where results will be stored
    ce_tot 			= [];
    Phis_tot 		= [];
    t_tot 			= [];
    Temperature_tot = [];
    SOC_tot         = [];
    Volts_tot       = [];
    Curr_dens       = [];
    % See the getCarCurrent.m file in order to understand how the piecewise
    % input currents have to be defined to properly run with LIONSIMBA
    param{1}.CurrentDensityFunction    = @getCarCurrent;

    % Start the simulations
    %%%%%%%%%%%%%%RANDOM%%%%%%%%%%%%%%%%%%%%
    
    % the ambient temperature is chosen at random between -10 and 50
    % degrees celsius
    % intial temperature of the cell ( do we want to change?)
    temp = randi([263,323],1,1);
    param{1}.T_init = temp;
    param{1}.Tref = temp;
    
    % results are created 100 times and stores ni results(i)
    % results(i) 	= startSimulation(t0,tf,initialState,[],param);
    run_n =1
    for i=1:length(timeinterval)
        % Set the final integration time
        tf 			= tf + timeinterval(i);
        % Start the simulations
        results 	= startSimulation(t0,tf,initialState,input_currents(i),param);
        % Concatenate the results
        if(run_n==1)
            ce_tot 						= [ce_tot;results.ce{1}];
            SOC_tot         			= [SOC_tot;results.SOC{1}];
            Phis_tot 					= [Phis_tot;results.Phis{1}];
            Temperature_tot 			= [Temperature_tot;results.Temperature{1}];
            Volts_tot                   = [Volts_tot;results.Voltage{1}];
            t_tot           			= [t_tot;results.time{1}];
            Curr_dens                   = [Curr_dens;results.curr_density];
            param{1}.JacobianFunction 	= results.JacobianFun;
            run_n = 2;
        else
            ce_tot 			= [ce_tot;results.ce{1}(2:end,:)];
            SOC_tot         = [SOC_tot;results.SOC{1}(2:end,:)];
            Phis_tot 		= [Phis_tot;results.Phis{1}(2:end,:)];
            Temperature_tot = [Temperature_tot;results.Temperature{1}(2:end,:)];
            Volts_tot       = [Volts_tot;results.Voltage{1}(2:end,:)]; 
            t_tot           = [t_tot;results.time{1}(2:end)];
            Curr_dens       = [Curr_dens;results.curr_density(2:end)];
        end
        % Update the initial states.
        initialState = results.initialState;
        % Update the starting integration time instant.
        t0 		= results.time{1}(end);

    end
    OutCellXT = [Curr_dens';
                 Volts_tot';
                 Temperature_tot(:,end)';
                 t_tot'];
    OutCellYT = [SOC_tot'];
    
    X_Train{end+1,1} = OutCellXT
    Y_Train{end+1,1} = OutCellYT
end




for i= 1:number_of_cycles
    %% for loop to output results to .csv
    
    % input temperature to variable 
    temp = results(i).Temperature{1};
    first_column_temp = temp(:,1);
    
    % generating .csv file name
    name_var = "results%d%d.csv";
    A = i;
    B = round(beginning_SOC);
    %C = round(temp);
    name = sprintf(name_var, A);
    path_directory = 'raw_data/Test/';
    path = strcat(path_directory,name);
    % storing results as 
    a = [results(i).time{1}, results(i).Voltage{1}, results(i).curr_density, results(i).SOC{1}, results(i).SOC_estimated{1}, first_column_temp];
    T = array2table(a);
    disp(path)
    T.Properties.VariableNames(1:6) = {'time','voltage','curr_density','SOC','SOC_est','temp'};
    writetable(T, path)
end
