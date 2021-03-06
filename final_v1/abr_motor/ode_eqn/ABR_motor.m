function dpop = ABR_motor(t, pop, comp_num, motor_params, abr_params, pflag)

run('compartment_cnt.m');
if motor_params('shifttime') > 0
    if t > motor_params('shifttime') ...
            && t < motor_params('shifttime') + motor_params('shiftduration')
        if pflag == "kbind"
            tmp_ = motor_params('kbind');
            motor_params('kbind') = tmp_ * motor_params('shiftmag');
        elseif pflag == "dragco"
            tmp_ = motor_params('dragco');
            motor_params('dragco') = tmp_ * motor_params('shiftmag');
        end
    end
end
        

% calculated cell velocity
v_cell = motor_params('dragco')*(sum(pop(bmp_start:bmp_end))...
    -sum(pop(bmn_start:bmn_end)));

%% Main Equations
% mglA
lap= abr_params.ka*pop(mglA_start+1)*pop(romR_start) ...
    -abr_params.da*pop(mglA_start)...
    -abr_params.dab*pop(mglA_start)*pop(mglB_start)^2;
rap= abr_params.ka*pop(mglA_end-1)*pop(romR_end) ...
    -abr_params.da*pop(mglA_end)...
    -abr_params.dab*pop(mglA_end)*pop(mglB_end)^2;

for i=mglA_start:mglA_end
    if i == mglA_start
        dpop(i,1)= lap ...
            - motor_params('kactive_motor')*pop(im_start)*pop(mglA_start)... 
            + motor_params('kdeactive_motor')* ...
            (pop(amp_start)+pop(amn_start))*pop(mglB_start)^2;
    elseif i == mglA_end
        dpop(i,1) = rap ...
            - motor_params('kactive_motor')*pop(im_end)*pop(mglA_end)... 
            + motor_params('kdeactive_motor')* ...
            (pop(amp_end)+pop(amn_end))*pop(mglB_end)^2;
    elseif i == mglA_start + 1
        dpop(i,1) = -lap ...
            + motor_params('diffco')...
            *(pop(mglA_start +2)-pop(mglA_start+1));
    elseif i == mglA_end - 1
        dpop(i,1) = -rap ...
            + motor_params('diffco') ...
            *(-pop(mglA_end-1)+pop(mglA_end-2));
    else
        dpop(i,1) = motor_params('diffco')*(pop(i+1)-2*pop(i)+pop(i-1));
    end
end


% mglB
lbp = pop(mglB_start+1)*(abr_params.kb+abr_params.kbb*pop(mglB_start)) ...
    -abr_params.db*(abr_params.K/(pop(mglB_start)+abr_params.K))...
    *pop(mglB_start)-abr_params.dba*pop(mglA_start)*pop(mglB_start)^2;
rbp = pop(mglB_end-1)*(abr_params.kb+abr_params.kbb*pop(mglB_end)) ...
    -abr_params.db*(abr_params.K/(pop(mglB_end)+abr_params.K))...
    *pop(mglB_end)-abr_params.dba*pop(mglA_end)*pop(mglB_end)^2;

for i = mglB_start:mglB_end
    
    if i == mglB_start
        dpop(i,1)= lbp; 
    elseif i ==mglB_start+1
        dpop(i,1)= -lbp ...
            + motor_params('diffco')*(pop(mglB_start+2)-pop(mglB_start+1));
    elseif i ==mglB_end-1
        dpop(i,1)= -rbp ...
            + motor_params('diffco')*(-pop(mglB_end-1)+pop(mglB_end-2));
    elseif i ==mglB_end
        dpop(i,1)=rbp;
    else 
        dpop(i,1)=motor_params('diffco')*(pop(i+1)-2*pop(i)+pop(i-1));
    end
end

    
% RomR
lrp = pop(romR_start+1)*(abr_params.kr+abr_params.krb*pop(mglB_start))...
    -abr_params.dr*pop(romR_start);
rrp = pop(romR_end-1)*(abr_params.kr+abr_params.krb*pop(mglB_end))...
    -abr_params.dr*pop(romR_end);

for i = romR_start:romR_end
    if i == romR_start
        dpop(i,1)= lrp; 
    elseif i ==romR_start+1
        dpop(i,1)= -lrp ...
            + motor_params('diffco')*(pop(romR_start+2)-pop(romR_start+1));
    elseif i ==romR_end-1
        dpop(i,1)= -rrp ...
            + motor_params('diffco')*(-pop(romR_end-1)+pop(romR_end-2));
    elseif i ==romR_end
        dpop(i,1)=rrp;
    else 
        dpop(i,1)=motor_params('diffco')*(pop(i+1)-2*pop(i)+pop(i-1));
    end
end

% free motor 
for i= im_start:im_end
    if i== im_start 
        dpop(i,1)= -motor_params('kactive_motor')...
            *pop(im_start)*pop(mglA_start)... 
            +motor_params('kdeactive_motor')...
            *(pop(amp_start)+pop(amn_start))*pop(mglB_start)^2 ...
            +motor_params('diffco_im')*(pop(im_start+1)-pop(im_start));
    elseif i== im_end
        dpop(i,1)= -motor_params('kactive_motor')...
            *pop(im_end)*pop(mglA_end)...
            +motor_params('kdeactive_motor')...
            *(pop(amp_end)+pop(amn_end))*pop(mglB_end)^2 ...
            +motor_params('diffco_im')*(pop(im_end-1)-pop(im_end));
    else
        dpop(i,1)=motor_params('diffco_im')*(pop(i+1)-2*pop(i)+pop(i-1));
    end
end


% active_free positive motor
for i = amp_start:amp_end 
    if i == amp_start
        dpop(i,1)=motor_params('kactive_motor')...
            *pop(im_start)*pop(mglA_start)...
            -motor_params('kdeactive_motor')...
            *pop(amp_start)*pop(mglB_start)^2 ...
            -motor_params('v_am')*pop(amp_start)...
            +motor_params('kreversal')*(pop(amn_start)-pop(amp_start))...
            +motor_params('diffco_am')*(pop(amp_start+1)-pop(amp_start))...
            -(v_cell<0)*v_cell*pop(bmp_start+1);
    elseif i == amp_end
        dpop(i,1)= -motor_params('kdeactive_motor')...
            *pop(amp_end)*pop(mglB_end)^2 ...
            +motor_params('v_am')*pop(amp_end-1)...
            +motor_params('kreversal')*(pop(amn_end)-pop(amp_end)) ...
            +motor_params('diffco_am')*(pop(amp_end-1)-pop(amp_end))...
            +(v_cell>0)*v_cell*pop(bmp_end-1); 
    else
        dpop(i,1)=motor_params('diffco_am')...
            *(pop(i+1)-2*pop(i)+pop(i-1)) ...
            +motor_params('v_am')*(pop(i-1)-pop(i))...
            +motor_params('kreversal')*(pop(i+comp_num)-pop(i))...
            -motor_params('kbind')*pop(i) ...
            +motor_params('kunbind')...
            *pop(i+(bmp_count-amp_count)*comp_num); 
           
    end
end


% active_free negative motor
for i=amn_start:amn_end
    if i == amn_start
        dpop(i,1)= -motor_params('kdeactive_motor')...
            *pop(amn_start)*pop(mglB_start)^2 ...
            +motor_params('v_am')*pop(amn_start+1)...
            +motor_params('kreversal')*(pop(amp_start)-pop(amn_start))...
            +motor_params('diffco_am')*(pop(amn_start+1)-pop(amn_start)) ...
            -(v_cell<0)*v_cell*pop(bmn_start+1);
        
    elseif i == amn_end
        dpop(i,1)=motor_params('kactive_motor')...
            *pop(im_end)*pop(mglA_end)...
            -motor_params('kdeactive_motor')...
            *pop(amn_end)*pop(mglB_end)^2 ...
            -motor_params('v_am')*pop(amn_end)...
            +motor_params('kreversal')*(pop(amp_end)-pop(amn_end)) ...
            +motor_params('diffco_am')*(pop(amn_end-1)-pop(amn_end)) ...
            +(v_cell>0)*v_cell*pop(bmn_end-1); 
        
    else
        dpop(i,1)=motor_params('diffco_am')*(pop(i+1)-2*pop(i)+pop(i-1))...
            +motor_params('v_am')*(pop(i+1)-pop(i))...
            +motor_params('kreversal')*(pop(i-comp_num)-pop(i))...
            -motor_params('kbind')*pop(i)...
            +motor_params('kunbind')*...
            pop(i+(bmn_count-amn_count)*comp_num);
    end
end

% bound positive motor 
for i =bmp_start:bmp_end
    if (i==bmp_start)|| (i==bmp_end)
        dpop(i,1)=0;
        
    elseif i==bmp_start+1
        dpop(i,1)=motor_params('diffco_bm')*(-pop(i)+pop(i+1)) ... 
            -motor_params('kunbind')*pop(i)...
            +motor_params('kbind')*pop(amp_start+1)...
            -(v_cell>0)*v_cell*pop(bmp_start+1) ...
            -(v_cell<0)*v_cell*(pop(bmp_start+2)-pop(bmp_start+1));
        
    elseif i==bmp_end-1
        dpop(i,1)=motor_params('diffco_bm')*(-pop(i)+pop(i-1))...
            -motor_params('kunbind')*pop(i) ...
            +motor_params('kbind')*pop(amp_end-1)...
            +(v_cell>0)*v_cell*(pop(bmp_end-2)-pop(bmp_end-1))...
            +(v_cell<0)*v_cell*pop(bmp_end-1);
    else
        dpop(i,1)=motor_params('diffco_bm')*(pop(i+1)-2*pop(i)+pop(i-1))...
            -motor_params('kunbind')*pop(i)...
            +motor_params('kbind')*pop(i-(bmp_count-amp_count)*comp_num) ...
            +(v_cell>0)*v_cell*(pop(i-1)-pop(i)) ...
            -(v_cell<0)*v_cell*(pop(i+1)-pop(i));
    end
end


% bound negative motor 
for i =bmn_start:bmn_end
    if (i==bmn_start)|| (i==bmn_end)
        dpop(i,1)=0;
    elseif i==bmn_start+1
        dpop(i,1)=motor_params('diffco_bm')*(-pop(i)+pop(i+1)) ... 
            -motor_params('kunbind')*pop(i) ...
            +motor_params('kbind')*pop(amn_start+1)...
            -(v_cell>0)*v_cell*pop(bmn_start+1) ...
            -(v_cell<0)*v_cell*(pop(bmn_start+2)-pop(bmn_start+1));
    elseif i==bmn_end-1
        dpop(i,1)=motor_params('diffco_bm')*(-pop(i)+pop(i-1))...
            -motor_params('kunbind')*pop(i) ...
            +motor_params('kbind')*pop(amn_end-1)...
            +(v_cell>0)*v_cell*(pop(bmn_end-2)-pop(bmn_end-1)) ...
            +(v_cell<0)*v_cell*pop(bmn_end-1);
    else
        dpop(i,1)=motor_params('diffco_bm')*(pop(i+1)-2*pop(i)+pop(i-1))...
            -motor_params('kunbind')*pop(i) ....
            +motor_params('kbind')*pop(i-(bmn_count-amn_count)*comp_num) ...
            +(v_cell>0)*v_cell*(pop(i-1)-pop(i)) ...
            -(v_cell<0)*v_cell*(pop(i+1)-pop(i));
    end
end

end   



