function decode_char=decode_command(out,step,readmode)


if readmode == 1
    a=out;
    decode_char=step*double(typecast(uint8([a]),'int32'));
elseif readmode == 2
    decode_char='';
    bytes_code=abs(typecast(uint32([out]),'uint8'));
    for ii = 1:length(bytes_code)
        hex_num = dec2hex(bytes_code(ii));
        %hex_num = num2str(bytes_code(ii));
        if length(hex_num)==1
            hex_num = ['0',hex_num];
        end
        decode_char=strcat(decode_char,hex_num);
    end
elseif readmode == 3
    a=out;
    decode_char=a./step;
    %decode_char=double(typecast(uint8([a]),'int32'))./step;
elseif readmode == 4
    decode_char = typecast(int32(out.*step),'uint8');
end

end


