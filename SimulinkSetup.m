%%
mdl = 'Teensy_Model';

%% Signals
MDCurrent = Simulink.Signal;
MDCurrent.Description = "MD_Current";
MDCurrent.DataType = "single";
MDCurrent.Complexity = "real";

MotorSpeed_In = Simulink.Signal;
MotorSpeed_In.Description = "MotorSpeed_In";
MotorSpeed_In.DataType = "single";
MotorSpeed_In.Complexity = "real";

TorqSpeed_In = Simulink.Signal;
TorqSpeed_In.Description = "TorqSpeed_In";
TorqSpeed_In.DataType = "single";
TorqSpeed_In.Complexity = "real";

Torq_Signal = Simulink.Signal;
Torq_Signal.Description = "Torq_Signal";
Torq_Signal.DataType = "single";
Torq_Signal.Complexity = "real";

%% Parameters
Status_LED = Simulink.Parameter;
Status_LED.Description = "Status_LED";
Status_LED.DataType = "boolean";
Status_LED.Value = 0;

Torq_Out = Simulink.Parameter;
Torq_Out.Description = "Torq_Out";
Torq_Out.DataType = "single";
Torq_Out.Value = 0;

Speed_Out = Simulink.Parameter;
Speed_Out.Description = "Speed_Out";
Speed_Out.DataType = "single";
Speed_Out.Value = 0;

Motor_Enable = Simulink.Parameter;
Motor_Enable.Description = "Motor_Enable";
Motor_Enable.DataType = "boolean";
Motor_Enable.Value = 0;

Motor_Stop = Simulink.Parameter;
Motor_Stop.Description = "Motor_Stop";
Motor_Stop.DataType = "boolean";
Motor_Stop.Value = 0;

Footcontrol = Simulink.Parameter;
Footcontrol.Description = "Footcontrol";
Footcontrol.DataType = "single";
Footcontrol.Value = 0;

%% Assign to model workspace
mws = get_param(mdl, 'ModelWorkspace');

assignin(mws, MDCurrent.Description, MDCurrent);
assignin(mws, MotorSpeed_In.Description, MotorSpeed_In);
assignin(mws, TorqSpeed_In.Description, TorqSpeed_In);

assignin(mws, Torq_Signal.Description, Torq_Signal);   % variable name without space

assignin(mws, Status_LED.Description, Status_LED);
assignin(mws, Torq_Out.Description, Torq_Out);
assignin(mws, Speed_Out.Description, Speed_Out);
assignin(mws, Motor_Enable.Description, Motor_Enable);
assignin(mws, Motor_Stop.Description, Motor_Stop);
assignin(mws, Footcontrol.Description, Footcontrol);