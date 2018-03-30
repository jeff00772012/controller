function controller_gui(para)

% 2018.03.29 Weishung
% input: para: parameter file 
%              ex: for thorlabs MCM3000 controller_gui('para_MCM')  
%       
%
% For mp285, no set zero command, need to apply it manually

MCMgui=figure('CloseRequestFcn',@my_closereq);

% read parameter inside para file
para_load=fopen(([pwd,'/',para,'.m']),'r');
count_para = 1;
while 1
    lines=fgetl(para_load);
    if lines == -1
        break;
    end
    chara=find(uint8(lines)==39);
  
        parameter{count_para}.para = lines(chara(1)+1:chara(2)-1);
    count_para=count_para+1;
end

which_obj=parameter{1}.para;
port_num=parameter{2}.para;
a=parameter{6}.para
% parameters for later usage
% arm movement:0.75s;
SampleRate=15;
counter_cum=0;
ini_x_pos=0;
ini_y_pos=0;
ini_z_pos=[];
controller=[];
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
            
            switch which_obj
                case 'MCM'
                    controller=MCM_controller(port_num);
                    obj_execute(controller,1)
                    set(zero_btn,'Enable','on')
                case 'MP285'
                    controller = SUTTER_controller(port_num);
                    fwrite(controller.COM,[controller.relative,controller.terminal],'uint8');
                    fread(controller.COM,1);
            end
            
            pos=obj_execute(which_obj,controller,1);
            
            set(pos_x,'String',num2str(pos(1)));
            set(pos_y,'String',num2str(pos(2)));
            set(pos_z,'String',num2str(pos(3)));
            
            daq_session = setup_daq(parameter{3}.para,parameter{4}.para,parameter{5}.para,parameter{6}.para);
            
            lh = addlistener(daq_session,'DataAvailable',@count_frames);
            
            set(connect_btn,'String','Break');
            set(Z_stack_start,'Enable','on')
            
            TimerData=timer('TimerFcn', {@update},'Period',1/SampleRate,'ExecutionMode','fixedRate','BusyMode','drop');
            start(TimerData)
            
        elseif state==0
            
            set(zero_btn,'Enable','off')
            set(Z_stack_start,'Enable','off')
            stop(TimerData)
            delete(TimerData)
            delete(daq_session)
            fclose(controller.COM);
            set(connect_btn,'String','Connect');
            
        end
    end

    function update(obj,eventdata, handles)
        
        pos=obj_execute(which_obj,controller,1);
        
        set(pos_x,'String',num2str(pos(1)));
        set(pos_y,'String',num2str(pos(2)));
        set(pos_z,'String',num2str(pos(3)));
    end

    function zeroing(obj,eventdata, handles)
        
        pos=obj_execute(which_obj,controller,2);
        
        set(pos_x,'String',num2str(pos(1)));
        set(pos_y,'String',num2str(pos(2)));
        set(pos_z,'String',num2str(pos(3)));
        
    end

    function count_frames(src,event)
        
        set(count_number,'String',num2str(event.Data(1,1)));
        
        if event.Data(1,2)-event.Data(1,1) > 0
            switch which_obj
                case 'MCM'
                    z_rising_pos=controller.read_command(controller.query_position_z,controller.min_step_z,1);
                case 'MP285'
                    z_rising_pos=controller.read_command(controller.query_position,controller.min_step,1);
                    z_rising_pos = z_rising_pos(3);
            end
            
            position(count)=z_rising_pos;
            count = count+1;
        end
        
        if event.Data(1,1)-counter_cum > 0 && event.Data(1,1) < str2double(get(edit_numberframes,'String'))
            tic
            
            z_next = ini_z_pos+str2double(get(edit_z_step,'String'))*counter_cum;
            switch which_obj
                case 'MCM'
                    z_next_norm = z_next/controller.min_step_z;
                    z_pos_mov = decode_command(z_next_norm,controller.min_step_z,2);
                    controller.goto_z((end-7):end)=z_pos_mov;
                    z_pos=controller.read_command(controller.goto_z,controller.min_step_z,2);
                case 'MP285'
                    z_next_norm = z_next*1000;
                    %z_pos_mov = decode_command(z_next_norm,controller.min_step,2);
                    %controller.goto_z((end-7):end)=z_pos_mov;
                    pos_all=[ini_x_pos,ini_y_pos,z_next_norm];
                    z_pos_mov = decode_command(pos_all,controller.min_step,4)
                    z_pos=controller.read_command([controller.movement_header,z_pos_mov],controller.min_step_z,2);
            end
            t=toc
            set(pos_z,'String',num2str(z_pos));
            counter_cum=counter_cum+str2double(get(edit_frameperstep_step,'String'))
        end
    end

    function z_stack_start(obj,eventdata, handles)
        if get(Z_stack_start,'Value')==1
            
            set(Z_stack_start,'String','Stop')
            startBackground(daq_session);
            
            pos=obj_execute(which_obj,controller,1);
            switch which_obj
                case 'MCM'
                    ini_z_pos=pos(3);
                case 'MP285'
                    ini_z_pos=0;
            end
        elseif get(Z_stack_start,'Value')==0
            set(Z_stack_start,'String','Start')
            
            switch which_obj
                case 'MCM'
                    
                    z_back = ini_z_pos/controller.min_step_z;
                    z_pos_mov = decode_command(z_back,controller.min_step_z,2);
                    controller.goto_z((end-7):end)=z_pos_mov;
                    z_pos=controller.read_command(controller.goto_z,controller.min_step_z,2);
                    
                case 'MP285'
                    z_back = ini_z_pos;
                    %z_pos_mov = decode_command(z_next_norm,controller.min_step,2);
                    %controller.goto_z((end-7):end)=z_pos_mov;
                    pos_all=[ini_x_pos,ini_y_pos,z_back];
                    z_pos_mov = decode_command(pos_all,controller.min_step,4);
                    z_pos=controller.read_command([controller.movement_header,z_pos_mov],controller.min_step_z,2);
            end
            
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