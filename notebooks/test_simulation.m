clear,clc
number_of_cycles = 2
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
    % Set the initial integration time
    t0 	= 0;
    tf  = 100;
    param{1}.OperatingMode     = 4;

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
    results(i) 	= startSimulation(t0,tf,initialState,[],param);
end

for i= 1:number_of_cycles
    column_names = {'time','Voltage','curr_density','SOC','SOC_estimated','Temperature'};
    writecell(column_names, 'test.xlsx','Sheet',i, 'Range', 'A1:F1')
    
    temp = results(i).Temperature{1};
    first_column_temp = temp(:,1);
    
    writematrix(results(i).time{1}, 'test.xlsx','Sheet',i, 'Range', 'A2')
    writematrix(results(i).Voltage{1}, 'test.xlsx','Sheet',i, 'Range', 'B2')
    writematrix(results(i).curr_density, 'test.xlsx','Sheet',i, 'Range', 'C2')
    writematrix(results(i).SOC{1}, 'test.xlsx','Sheet',i, 'Range', 'D2')
    writematrix(results(i).SOC_estimated{1}, 'test.xlsx','Sheet',i, 'Range', 'E2')
    writematrix(first_column_temp, 'test.xlsx','Sheet',i, 'Range', 'F2')
end
