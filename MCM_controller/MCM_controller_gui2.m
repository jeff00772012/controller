function MCM_controller_gui2


MCMgui=figure('CloseRequestFcn',@my_closereq);

% parameters for later usage
% arm movement:0.75s; 
SampleRate=15;
counter_cum=0;
ini_z_pos=[];
MCM=[];
TimerData=[];
daq_session=[];

% texts
uicontrol('Style','text','Position',[10 350 120 50],'String','X:','FontSize',20);
uicontrol('Style','text','Position',[10 300 120 50],'String','Y:','FontSize',20);
uicontrol('Style','text','Position',[10 250 120 50],'String','Z:','FontSize',20);

uicontrol('Style','text','Position',[10 200 120 50],'String','Z step:','FontSize',20);
uicontrol('Style','text','Position',[240 200 50 50],'String','mm','FontSize',20);
uicontrol('Style','text','Position',[300 200 120 50],'String','Frames:','FontSize',15);

uicontrol('Style','text','Position',[10 130 100 50],'String','Frames per stack:','FontSize',15);
uicontrol('Style','text','Position',[10 10 150 70],'String','Total number of frames:','FontSize',12);

% buttons and editbox that will be used at later procedure
edit_numberframes = uicontrol('Style','edit','Position',[160 35 120 50],'String','20','FontSize',20);
edit_z_step = uicontrol('Style','edit','Position',[120 200 120 50],'String','0.005','FontSize',20);

edit_frameperstep_step = uicontrol('Style','edit','Position',[120 130 120 50],'String','1','FontSize',20);

connect_btn = uicontrol('Style','togglebutton','Position',[340 350 120 50],'String','Connect',...
    'FontSize',20,'Value',0,'Callback',@connect_serial);

pos_x = uicontrol('Style','text','Position',[80 360 120 30],'String','','FontSize',12);
pos_y = uicontrol('Style','text','Position',[80 310 120 30],'String','','FontSize',12);
pos_z = uicontrol('Style','text','Position',[80 260 120 30],'String','','FontSize',12);

zero_btn = uicontrol('Style','pushbutton','Position',[340 300 120 50],'String','Zeroing',...
    'FontSize',20,'Value',0,'Callback',@zeroing);
Z_stack_start = uicontrol('Style','togglebutton','Position',[340 120 120 50],'String','Start',...
    'FontSize',20,'Value',0,'Callback',@z_stack_start);

count_number = uicontrol('Style','text','Position',[420 200 50 50],'String','0','FontSize',15);

set(zero_btn,'Enable','off')
set(Z_stack_start,'Enable','off')

position=zeros(1,1000);
count=1;
file_count=1;


% connect matlab to COM serial port
    function connect_serial(obj,eventdata, handles)
        state = get(connect_btn,'Value');
        if state == 1
            
            
            MCM=MCM_controller;
            
            daq_session = daq.createSession('ni');
            ch=addCounterInputChannel(daq_session,'Dev1', 'ctr2', 'EdgeCount');
            ch2=addCounterInputChannel(daq_session,'Dev1', 'ctr0', 'EdgeCount');
            addAnalogInputChannel(daq_session,'Dev1', 'ai4', 'Voltage');
            daq_session.IsContinuous=true;
            
            ch.ActiveEdge = 'Falling';
            ch2.ActiveEdge = 'Rising';
            
            lh = addlistener(daq_session,'DataAvailable',@count_frames);
            
            set(connect_btn,'String','Break');
            
            set(zero_btn,'Enable','on')
            set(Z_stack_start,'Enable','on')
            
            TimerData=timer('TimerFcn', {@update},'Period',1/SampleRate,'ExecutionMode','fixedRate','BusyMode','drop');
            
            x_initial=MCM.read_command(MCM.query_position_x,MCM.min_step_xy,1);
            y_initial=MCM.read_command(MCM.query_position_y,MCM.min_step_xy,1);
            z_initial=MCM.read_command(MCM.query_position_z,MCM.min_step_z,1);
            set(pos_x,'String',num2str(x_initial));
            set(pos_y,'String',num2str(y_initial));
            set(pos_z,'String',num2str(z_initial));
            
            start(TimerData)
            
        elseif state==0
            
            set(zero_btn,'Enable','off')
            set(Z_stack_start,'Enable','off')
            stop(TimerData)
            delete(TimerData)
            delete(daq_session)
            fclose(MCM.COM);
            set(connect_btn,'String','Connect');
            
        end
    end

    function update(obj,eventdata, handles)
        
        x_current=MCM.read_command(MCM.query_position_x,MCM.min_step_xy,1);
        y_current=MCM.read_command(MCM.query_position_y,MCM.min_step_xy,1);
        z_current=MCM.read_command(MCM.query_position_z,MCM.min_step_z,1);
        set(pos_x,'String',num2str(x_current));
        set(pos_y,'String',num2str(y_current));
        set(pos_z,'String',num2str(z_current));
        
    end

    function zeroing(obj,eventdata, handles)
        
        x_zero=MCM.read_command(MCM.set_zero_message_x,MCM.min_step_xy,0);
        y_zero=MCM.read_command(MCM.set_zero_message_y,MCM.min_step_xy,0);
        z_zero=MCM.read_command(MCM.set_zero_message_z,MCM.min_step_z,0);
        
        x_zero=MCM.read_command(MCM.query_position_x,MCM.min_step_xy,1);
        y_zero=MCM.read_command(MCM.query_position_y,MCM.min_step_xy,1);
        z_zero=MCM.read_command(MCM.query_position_z,MCM.min_step_z,1);
        
        set(pos_x,'String',num2str(x_zero));
        set(pos_y,'String',num2str(y_zero));
        set(pos_z,'String',num2str(z_zero));
        
    end

    function count_frames(src,event)
        
        set(count_number,'String',num2str(event.Data(1,1)));
        
        if event.Data(1,2)-event.Data(1,1) > 0
            z_rising_pos=MCM.read_command(MCM.query_position_z,MCM.min_step_z,1);
            position(count)=z_rising_pos;
            count = count+1;
        end
        
        if event.Data(1,1)-counter_cum > 0 && event.Data(1,1) < str2double(get(edit_numberframes,'String'))
            tic
            
            z_next = ini_z_pos+str2double(get(edit_z_step,'String'))*counter_cum;
            z_next_norm = z_next/MCM.min_step_z;
            z_pos_mov = decode_command(z_next_norm,MCM.min_step_z,2);
            MCM.goto_z((end-7):end)=z_pos_mov;
            z_pos=MCM.read_command(MCM.goto_z,MCM.min_step_z,2);
            t=toc
            set(pos_z,'String',num2str(z_pos));
            counter_cum=counter_cum+str2double(get(edit_frameperstep_step,'String'));
        end
    end

    function z_stack_start(obj,eventdata, handles)
        if get(Z_stack_start,'Value')==1
            
            set(Z_stack_start,'String','Stop')
            
            startBackground(daq_session);
            x_pos=MCM.read_command(MCM.query_position_x,MCM.min_step_xy,1);
            y_pos=MCM.read_command(MCM.query_position_y,MCM.min_step_xy,1);
            z_pos=MCM.read_command(MCM.query_position_z,MCM.min_step_z,1);
            
            
            
            z_stack_step=str2double(get(edit_z_step,'String'));
            ini_z_pos=z_pos;
            
        elseif get(Z_stack_start,'Value')==0
            set(Z_stack_start,'String','Start')
            
            z_back = ini_z_pos/MCM.min_step_z;
            z_pos_mov = decode_command(z_back,MCM.min_step_z,2);
            MCM.goto_z((end-7):end)=z_pos_mov;
            z_pos=MCM.read_command(MCM.goto_z,MCM.min_step_z,2);
            save(['position_' num2str(file_count)],'position');
            file_count=file_count + 1;
            position=zeros(1,1000);
            counter_cum=0;
            stop(daq_session)
        end
        
    end

    function my_closereq(src,callbackdata)
        % Close request function
        % to display a question dialog box
        if get(connect_btn,'Value') == 1
            errordlg('Please break connection','Error');
        else
            selection = questdlg('Close This Figure?',...
                'Close Request Function',...
                'Yes','No','Yes');
            switch selection
                case 'Yes'
                    delete(gcf)
                case 'No'
                    return
            end
        end
    end
end