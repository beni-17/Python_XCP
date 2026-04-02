# Python_XCP
Proof of concept, Python to Teensy connection with serial XCP

# Simulink
to generate a2l file, open simulink 
 In the Hardware tab of Simulink toolstrip, click Build for Monitoring. This action builds the model and generates the executable along with the A2L file in the current MATLAB® folder path. The A2L file contains XCP server information for using in third-party calibration tools. The file name of the A2L file is in this format: modelname.a2l
 Click Deploy in the Simulink Toolstrip to deploy the executable onto the target.

# Hardware
Teensy 4.1 is used as hardware
follow example: https://ch.mathworks.com/help/simulink/supportpkg/arduino_ref/calibrate-ecu-canape-example.html
to set up the Teensy and to obtain the .a2l File

# python
Setup of python project:
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# A2L in matlab
https://ch.mathworks.com/help/vnt/ug/get-started-with-a2l-files.html

