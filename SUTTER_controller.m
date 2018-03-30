classdef SUTTER_controller < handle
    properties
        
        COM
        min_step=25;
        query_position = uint8(99);
        relative=uint8(98)
       
        min_step_z=25;
        query_position_z = uint8(99);
        
        movement_header = uint8(109);
        terminal = uint8(13);
    end
    methods
        
        function obj=SUTTER_controller(port_num)
            obj.COM = port_num;
            baud = 9600;
            bytesize = 8;
            stopbits = 1;
            delete(instrfindall) %deletes any established open serial ports to avoid errors when creating or opening ports
            obj.COM = serial(obj.COM,'BaudRate',baud,'DataBits',bytesize,'StopBits',stopbits);
            fopen(obj.COM)
        end
        
        function pos=read_command(obj,message,min_step,readmode)
            
            fwrite(obj.COM,[message,obj.terminal],'uint8');
            if readmode == 1
                out=fread(obj.COM,3,'int32');
                pos=decode_command(out,min_step,3);   
                remain=fread(obj.COM,1);
            elseif readmode == 2
                remain=fread(obj.COM,1);
                pos=[];
            else
                pos=[];
            end
        end
        
    end
    
end