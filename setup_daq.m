function daq_session = setup_daq(daq_name,counter1,counter2,ai)
%SETUP_DAQ Summary of this function goes here
%   Detailed explanation goes here

daq_session = daq.createSession('ni');
ch=addCounterInputChannel(daq_session,daq_name, counter1, 'EdgeCount');
ch2=addCounterInputChannel(daq_session,daq_name, counter2, 'EdgeCount');
addAnalogInputChannel(daq_session,daq_name, ai, 'Voltage');
daq_session.IsContinuous=true;

ch.ActiveEdge = 'Falling';
ch2.ActiveEdge = 'Rising';
end

