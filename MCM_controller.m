classdef MCM_controller < handle
    properties
        
        COM
        min_step_xy=0.0005;
        min_step_z=0.000212;
        set_zero_message_x = '090406000000000000000000';
        set_zero_message_y = '090406000000010000000000';
        set_zero_message_z = '090406000000020000000000';
               
        query_position_x = '0A0400000000';
        query_position_y = '0A0401000000';
        query_position_z = '0A0402000000';
        
        goto_x='530406000000000000000000';
        goto_y='530406000000010000000000';
        goto_z='530406000000020000000000';
    end
    methods
        
        function obj=MCM_controller(port_num)
            obj.COM = port_num;
            baud = 9600;
            bytesize = 8;
            stopbits = 1;
            delete(instrfindall) %deletes any established open serial ports to avoid errors when creating or opening ports
            obj.COM = serial(obj.COM,'BaudRate',baud,'DataBits',bytesize,'StopBits',stopbits);
            fopen(obj.COM);
        end
        
        function pos=read_command(obj,message,min_step,readmode)
            send_msg = sscanf(message, '%2x');
            fwrite(obj.COM,send_msg, 'uint8')
            if readmode == 1
                read_length=12;
                out=fread(obj.COM,read_length);
                pos=decode_command(out(9:12),min_step,1);
            else
                pos=[];
            end
        end
        
    end
    
end