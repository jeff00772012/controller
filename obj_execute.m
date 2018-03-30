function pos=obj_execute(which_obj,controller,command)

switch which_obj
    case 'MCM'
        if command == 1
            x_initial=controller.read_command(controller.query_position_x,controller.min_step_xy,1);
            y_initial=controller.read_command(controller.query_position_y,controller.min_step_xy,1);
            z_initial=controller.read_command(controller.query_position_z,controller.min_step_z,1);
            pos=[x_initial,y_initial,z_initial];
        elseif command == 2
            x_zero=controller.read_command(controller.set_zero_message_x,controller.min_step_xy,0);
            y_zero=controller.read_command(controller.set_zero_message_y,controller.min_step_xy,0);
            z_zero=controller.read_command(controller.set_zero_message_z,controller.min_step_z,0);
            
            x_zero=controller.read_command(controller.query_position_x,controller.min_step_xy,1);
            y_zero=controller.read_command(controller.query_position_y,controller.min_step_xy,1);
            z_zero=controller.read_command(controller.query_position_z,controller.min_step_z,1);
            
            pos = [x_zero,y_zero,z_zero];
            
        end
    case 'MP285'
        if command == 1
            pos=controller.read_command(controller.query_position,controller.min_step,1);
        end
end

end

