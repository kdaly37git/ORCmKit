function [out_ORC, TS_ORC] = OrcModel2bis(fluid_wf, fluid_htf, in_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param)
%% CODE DESCRIPTION
% ORCmKit - an open-source modelling library for ORC systems

% Remi Dickes - 28/04/2016 (University of Liege, Thermodynamics Laboratory)
% rdickes @ulg.ac.be
%
% OrcModel is a single matlab function developed to calculate the steady-state
% equilibrium conditions of an ORC (see the Documentation/HexModel_MatlabDoc)
%
% The model inputs are:
%       - fluid_wf: nature of the working fluid                     [-]
%       - fluid_htf: nature of the hot source fluid                 [-]
%       - in_htf_su: inlet temperature or enthalpy of the hot source[K or J/kg]
%       - P_htf_su: inlet pressure of the hot source                [Pa]
%       - m_dot_htf: mass flow rate of the hot source               [kg/s]
%       - fluid_ctf: nature of the hot source fluid                 [-]
%       - in_ctf_su: inlet temperature or enthalpy of the hot source[K or J/kg]
%       - P_ctf_su: inlet pressure of the hot source                [Pa]
%       - m_dot_ctf: mass flow rate of the hot source               [kg/s]
%       - T_amb : ambient temperature                               [K]
%       - N_exp : expander speed                                    [rpm]
%       - N_pp  : pump speed                                        [rpm]
%       - param: structure variable containing the model parameters
%
% Please refer to the docucmentation of HexModel, PumpModel, ExpanderModel
% and LossesModel for further details about the component models
%
% The model outputs are:
%       - out: a structure variable which includes at miniumum the following information:
%
%       - TS : a stucture variable which contains the vectors of temperature
%              and entropy of the fluid (useful to generate a Ts diagram
%              when modelling the entire ORC system
%
% See the documentation for further details or contact rdickes@ulg.ac.be

%% DEMONSTRATION CASE
if nargin == 0
    
    fluid_wf = 'R245fa';
    fluid_htf = 'PiroblocBasic';
    P_htf_su = 2e5;
    in_htf_su = 379.4284;
    m_dot_htf = 0.9294;
    fluid_ctf = 'air';
    P_ctf_su = 1e5;
    in_ctf_su = 4.1725e+05;
    m_dot_ctf = 1.4136;
    T_amb = 291.0039;
    N_exp = 5000;
    N_pp = 200;
    param.solverType = 'M_imposed';
    param.DT_sc = 9.0787;
    param.x_cd_ex = 0;
    param.M_tot = 25;
    
    path = 'C:\Users\RDickes\Google Drive\PhD\MOR study\ORC\Experimental database\Sun2Power';
    
    EV_folder = [path '\Evaporator\'];
    load([EV_folder, 'ParametersCalibration_EV.mat'])
    param.EV = EV_hConvVar;
    param.EV.V_h_tot = 0.009;
    param.EV.V_c_tot = 0.009;
    param.EV.displayResults = 0;
    param.EV.displayTS = 0;
    
    CD_folder = [path '\Condenser\'];
    load([CD_folder, 'ParametersCalibration_CD.mat'])
    param.CD = CD_hConvVar;
    param.CD.V_h_tot = 0.014;
    param.CD.V_c_tot = 0.7585;
    param.CD.displayResults = 0;
    param.CD.displayTS = 0;
    param.CD.W_dot_aux = 0;
    
    REC_folder = [path '\Recuperator\'];
    load([REC_folder, 'ParametersCalibration_REC.mat'])
    param.REC = REC_hConvVar;
    param.REC.V_h_tot = 0.001026;
    param.REC.V_c_tot = 0.00108;
    param.REC.displayResults = 0;
    param.REC.displayTS = 0;
    
    PP_folder = [path '\Pump\'];
    load([PP_folder, 'ParametersCalibration_PP.mat'])
    param.PP = PP_SemiEmp;
    param.PP.V = 1.4e-3;
    param.PP.displayResults = 0;
    param.PP.displayTS = 0;
    
    EXP_folder = [path '\Expander\'];
    load([EXP_folder, 'ParametersCalibration_EXP.mat'])
    param.EXP = EXP_SemiEmp;
    param.EXP.modelType = 'SemiEmp';
    param.EXP.V = 1.4e-3;
    param.EXP.displayResults = 0;
    param.EXP.displayTS = 0;
    load('C:\Users\RDickes\Google Drive\PhD\MOR study\ORC\Experimental database\Sun2Power\OffDesign\gamma_R245fa.mat');
    param.EXP.gamma.gamma_PQ_pol = gamma_PQ_R245fa; param.EXP.gamma.gamma_PT_pol = gamma_PT_R245fa;
    
    DP_folder = [path '\PressureDrops\'];
    load([DP_folder, 'ParametersCalibration_DP.mat'])
    param.LossesHP = DPHP_PhiDP;
    param.LossesHP.displayResults = 0;
    param.LossesHP.displayTS = 0;
    
    param.LossesLP = DPLP_PhiDP;
    param.LossesLP.displayResults = 0;
    param.LossesLP.displayTS = 0;
    
    param.V_aux_pp_ex =  2.21035e-4;
    param.V_aux_recc_ex = 9.54259e-5;
    param.V_aux_ev_ex = 9.54259e-5;
    param.V_aux_exp_ex =  7.08995e-4;
    param.V_aux_rech_ex = 7.01469e-4;
    param.V_liq_rec = 5.7e-3;
    param.V_aux_cd_ex = 5.991508e-3 - param.V_liq_rec;
    param.displayTS = 1;
    param.displayResults =0;
    
    param.init = [ 2 2 2 2];
    param.nbr_test = 1;
    param.display = 1;
end

tstart_ORC = tic;

if strcmp(param.CD.type_c, 'T')
    T_ctf_su = in_ctf_su;
else
    T_ctf_su = CoolProp.PropsSI('T', 'H', in_ctf_su, 'P', P_ctf_su, fluid_ctf);
end
if strcmp(param.EV.type_h, 'T')
    T_htf_su = in_htf_su;
else
    T_htf_su = CoolProp.PropsSI('T', 'H', in_htf_su, 'P', P_htf_su, fluid_htf);
end

%% ORC MODELING
if strcmp(param.solverType, 'DTsc_imposed') %% CASE 1 : subcooling imposed
    
    % Initial conditions evaluation
    IC = InitialConditions_ORC_Ext_Npp_Nexp_2(fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param);
    if max(param.init) <2
        if length(IC.res) < 1 || IC.res > 1
            out_ORC.flag_ORC = - 1;
            TS_ORC = NaN;
            return
        end
    end
    
    % Order guesses results
    [res_ordered, j_order] = sort(IC.res);
    Nbr_comb_x0 = length(j_order);
    Nbr_comb_x0_max = param.nbr_test;
    if param.display
        disp('x0 residuals and index:')
        fprintf('\n');
        disp(num2str([j_order(1:min(Nbr_comb_x0,Nbr_comb_x0_max)); res_ordered(1:min(Nbr_comb_x0,Nbr_comb_x0_max))]))
        fprintf('\n');
    end
    
    % Start evaluation
    if not(isempty(res_ordered))
        
        if param.display
            fprintf('\n');
            disp('Start iteration:')
            fprintf('\n');
            fprintf('%-10s %-5s %-60s %-15s %-60s %-60s %-10s %-100s\n', '#', 'i0', 'x_in', 'res_in', 'x_out', 'res_out', 'flag_ORC', 'flag components');
            fprintf('\n');
        end
        k= 1;
        out_ORC_best.res = 1e10;
        stop = 0;
        options_fmincon = optimset('Disp','iter','Algorithm','interior-point','UseParallel',false,'TolX',1e-13,'TolFun',1e-13,'TolCon',1e-6,'MaxIter',1e3,'OutputFcn',@outputfunFS);
        
        while not(stop) && k <= min(Nbr_comb_x0,Nbr_comb_x0_max);
            
%             if strcmp(param.solverType, 'DTsc_imposed')
                x0 = [IC.P_pp_ex_guess_vec(j_order(k))    IC.P_pp_su_guess_vec(j_order(k))    IC.h_ev_ex_guess_vec(j_order(k))];
                ub = [IC.P_pp_ex_ub_vec(j_order(k))       IC.P_pp_su_ub_vec(j_order(k))       IC.h_ev_ex_ub_vec(j_order(k))];
                lb = [IC.P_pp_ex_lb_vec(j_order(k))       IC.P_pp_su_lb_vec(j_order(k))       IC.h_ev_ex_lb_vec(j_order(k))];
                A_ineq = [-1 1.001 0]; B_ineq = [0];
%             elseif strcmp(param.solverType, 'M_imposed')
%                 x0 = [IC.P_pp_ex_guess_vec(j_order(k))    IC.P_pp_su_guess_vec(j_order(k))    IC.h_ev_ex_guess_vec(j_order(k))     IC.h_pp_su_guess_vec(j_order(k))];
%                 ub = [IC.P_pp_ex_ub_vec(j_order(k))       IC.P_pp_su_ub_vec(j_order(k))       IC.h_ev_ex_ub_vec(j_order(k))        IC.h_pp_su_ub_vec(j_order(k))];
%                 lb = [IC.P_pp_ex_lb_vec(j_order(k))       IC.P_pp_su_lb_vec(j_order(k))       IC.h_ev_ex_lb_vec(j_order(k))        IC.h_pp_su_lb_vec(j_order(k))];
%                 A_ineq = [-1 1.001 0 0]; B_ineq = [0];
%             end
            if param.display
                fprintf('%-10s %-5d %-60s %-15s ', [num2str(k) '/' num2str(min(Nbr_comb_x0,Nbr_comb_x0_max))] , j_order(k), ['[' num2str(x0,'%15.4e') ']'] , num2str(IC.res(j_order(k)), '%.4g'));
            end
            param.eval_type = 'fast';
            f = @(x) FCT_ORC_Ext_Npp_Nexp_res_2( x, lb, ub, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param);
            x = fmincon(f,x0./ub,A_ineq,B_ineq,[],[],lb./ub,ub./ub,[],options_fmincon);
            param.eval_type = 'long';
            [out_ORC, TS_ORC] = FCT_ORC_Ext_Npp_Nexp_2(x, lb, ub, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param);
            
            if any(out_ORC.flag.value<0)
                out_ORC.flag_ORC = - 1;
                stop = 0;
            elseif all(out_ORC.flag.value>0) && any(abs(out_ORC.res_vec) > 5e-5)
                out_ORC.flag_ORC = -2;
                stop = 0;
            else
                out_ORC.flag_ORC = 1;
                stop = 1;
            end
            if param.display
                fprintf('%-60s %-60s %-10s %-100s \n', ['[' num2str(x.*ub,'%15.4e') ']'], [ num2str(out_ORC.res, '%.4g') '  [ ' num2str(out_ORC.res_vec,'%15.4e') ' ] '], num2str(out_ORC.flag_ORC), num2str(out_ORC.flag.value));
            end
            if out_ORC.res < out_ORC_best.res
                out_ORC_best = out_ORC;
            end
            out_ORC = out_ORC_best;
            k = k+1;
        end
    else
        out_ORC.flag_ORC = - 1;
        TS_ORC = NaN;
    end
    
    
elseif strcmp(param.solverType, 'M_imposed')  %% CASE 2 : REFRIGERANT MASS IMPOSED
    
    % Scenario #1 : saturated liquid at the pump supply
    param_liq0 = param;
    param_liq0.solverType = 'DTsc_imposed';
    param_liq0.DT_sc = 0;
    
    % Initial conditions evaluation
    IC_liq0 = InitialConditions_ORC_Ext_Npp_Nexp_2(fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param_liq0);
    if max(param.init) <2
        if length(IC_liq0.res) < 1 || IC_liq0.res > 1
            out_ORC.flag_ORC = - 1;
            TS_ORC = NaN;
            return
        end
    end
    
    % Order guesses results
    [res_ordered, j_order] = sort(IC_liq0.res);
    Nbr_comb_x0 = length(j_order);
    Nbr_comb_x0_max = param.nbr_test;
    if param.display
        disp('x0 residuals and index:')
        fprintf('\n');
        disp(num2str([j_order(1:min(Nbr_comb_x0,Nbr_comb_x0_max)); res_ordered(1:min(Nbr_comb_x0,Nbr_comb_x0_max))]))
        fprintf('\n');
    end
    
    % Start evaluation
    if not(isempty(res_ordered))
        
        if param.display
            fprintf('\n');
            disp('Start iteration:')
            fprintf('\n');
            fprintf('%-10s %-5s %-60s %-15s %-60s %-60s %-10s %-100s\n', '#', 'i0', 'x_in', 'res_in', 'x_out', 'res_out', 'flag_ORC', 'flag components');
            fprintf('\n');
        end
        k= 1;
        out_ORC_best.res = 1e10;
        stop = 0;
        options_fmincon = optimset('Disp','iter','Algorithm','interior-point','UseParallel',false,'TolX',1e-13,'TolFun',1e-13,'TolCon',1e-6,'MaxIter',1e3,'OutputFcn',@outputfunFS);
        
        while not(stop) && k <= min(Nbr_comb_x0,Nbr_comb_x0_max);
            
%             if strcmp(param.solverType, 'DTsc_imposed')
                x0 = [IC_liq0.P_pp_ex_guess_vec(j_order(k))    IC_liq0.P_pp_su_guess_vec(j_order(k))    IC_liq0.h_ev_ex_guess_vec(j_order(k))];
                ub = [IC_liq0.P_pp_ex_ub_vec(j_order(k))       IC_liq0.P_pp_su_ub_vec(j_order(k))       IC_liq0.h_ev_ex_ub_vec(j_order(k))];
                lb = [IC_liq0.P_pp_ex_lb_vec(j_order(k))       IC_liq0.P_pp_su_lb_vec(j_order(k))       IC_liq0.h_ev_ex_lb_vec(j_order(k))];
                A_ineq = [-1 1.001 0]; B_ineq = [0];
%             elseif strcmp(param.solverType, 'M_imposed')
%                 x0 = [IC.P_pp_ex_guess_vec(j_order(k))    IC.P_pp_su_guess_vec(j_order(k))    IC.h_ev_ex_guess_vec(j_order(k))     IC.h_pp_su_guess_vec(j_order(k))];
%                 ub = [IC.P_pp_ex_ub_vec(j_order(k))       IC.P_pp_su_ub_vec(j_order(k))       IC.h_ev_ex_ub_vec(j_order(k))        IC.h_pp_su_ub_vec(j_order(k))];
%                 lb = [IC.P_pp_ex_lb_vec(j_order(k))       IC.P_pp_su_lb_vec(j_order(k))       IC.h_ev_ex_lb_vec(j_order(k))        IC.h_pp_su_lb_vec(j_order(k))];
%                 A_ineq = [-1 1.001 0 0]; B_ineq = [0];
%             end
            if param.display
                fprintf('%-10s %-5d %-60s %-15s ', [num2str(k) '/' num2str(min(Nbr_comb_x0,Nbr_comb_x0_max))] , j_order(k), ['[' num2str(x0,'%15.4e') ']'] , num2str(IC_liq0.res(j_order(k)), '%.4g'));
            end
            param_liq0.eval_type = 'fast';
            f = @(x) FCT_ORC_Ext_Npp_Nexp_res_2( x, lb, ub, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param_liq0);
            x = fmincon(f,x0./ub,A_ineq,B_ineq,[],[],lb./ub,ub./ub,[],options_fmincon);
            param_liq0.eval_type = 'long';
            [out_ORC, TS_ORC] = FCT_ORC_Ext_Npp_Nexp_2(x, lb, ub, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param_liq0);
            
            if any(out_ORC.flag.value<0)
                out_ORC.flag_ORC = - 1;
                stop = 0;
            elseif all(out_ORC.flag.value>0) && any(abs(out_ORC.res_vec) > 5e-5)
                out_ORC.flag_ORC = -2;
                stop = 0;
            else
                out_ORC.flag_ORC = 1;
                stop = 1;
            end
            if param.display
                fprintf('%-60s %-60s %-10s %-100s \n', ['[' num2str(x.*ub,'%15.4e') ']'], [ num2str(out_ORC.res, '%.4g') '  [ ' num2str(out_ORC.res_vec,'%15.4e') ' ] '], num2str(out_ORC.flag_ORC), num2str(out_ORC.flag.value));
            end
            if out_ORC.res < out_ORC_best.res
                out_ORC_best = out_ORC;
            end
            out_ORC = out_ORC_best;
            k = k+1;
        end
        
        if out_ORC.level_receiver <= 1 && out_ORC.level_receiver >= 0
            sub_cooled_eval = 0;
        else
            sub_cooled_eval = 1;
        end
    else
        out_ORC.flag_ORC = - 1;
        TS_ORC = NaN;
        sub_cooled_eval = 1;
    end
    
    if sub_cooled_eval
        clear out_ORC TS_ORC
        
        % Initial conditions evaluation
        IC = InitialConditions_ORC_Ext_Npp_Nexp_2(fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param);
        if max(param.init) <2
            if length(IC.res) < 1 || IC.res > 1
                out_ORC.flag_ORC = - 1;
                TS_ORC = NaN;
                return
            end
        end
        
        % Order guesses results
        [res_ordered, j_order] = sort(IC.res);
        Nbr_comb_x0 = length(j_order);
        Nbr_comb_x0_max = param.nbr_test;
        if param.display
            disp('x0 residuals and index:')
            fprintf('\n');
            disp(num2str([j_order(1:min(Nbr_comb_x0,Nbr_comb_x0_max)); res_ordered(1:min(Nbr_comb_x0,Nbr_comb_x0_max))]))
            fprintf('\n');
        end
        
        % Start evaluation
        if not(isempty(res_ordered))
            
            if param.display
                fprintf('\n');
                disp('Start iteration:')
                fprintf('\n');
                fprintf('%-10s %-5s %-60s %-15s %-60s %-60s %-10s %-100s\n', '#', 'i0', 'x_in', 'res_in', 'x_out', 'res_out', 'flag_ORC', 'flag components');
                fprintf('\n');
            end
            k= 1;
            out_ORC_best.res = 1e10;
            stop = 0;
            options_fmincon = optimset('Disp','iter','Algorithm','interior-point','UseParallel',false,'TolX',1e-13,'TolFun',1e-13,'TolCon',1e-6,'MaxIter',1e3,'OutputFcn',@outputfunFS);
            
            while not(stop) && k <= min(Nbr_comb_x0,Nbr_comb_x0_max);
                
                x0 = [IC.P_pp_ex_guess_vec(j_order(k))    IC.P_pp_su_guess_vec(j_order(k))    IC.h_ev_ex_guess_vec(j_order(k))     IC.h_pp_su_guess_vec(j_order(k))];
                ub = [IC.P_pp_ex_ub_vec(j_order(k))       IC.P_pp_su_ub_vec(j_order(k))       IC.h_ev_ex_ub_vec(j_order(k))        IC.h_pp_su_ub_vec(j_order(k))];
                lb = [IC.P_pp_ex_lb_vec(j_order(k))       IC.P_pp_su_lb_vec(j_order(k))       IC.h_ev_ex_lb_vec(j_order(k))        IC.h_pp_su_lb_vec(j_order(k))];
                A_ineq = [-1 1.001 0 0]; B_ineq = [0];
                if param.display
                    fprintf('%-10s %-5d %-60s %-15s ', [num2str(k) '/' num2str(min(Nbr_comb_x0,Nbr_comb_x0_max))] , j_order(k), ['[' num2str(x0,'%15.4e') ']'] , num2str(IC.res(j_order(k)), '%.4g'));
                end
                param.eval_type = 'fast';
                f = @(x) FCT_ORC_Ext_Npp_Nexp_res_2( x, lb, ub, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param);
                x = fmincon(f,x0./ub,A_ineq,B_ineq,[],[],lb./ub,ub./ub,[],options_fmincon);
                param.eval_type = 'long';
                [out_ORC, TS_ORC] = FCT_ORC_Ext_Npp_Nexp_2(x, lb, ub, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param);
                
                if any(out_ORC.flag.value<0)
                    out_ORC.flag_ORC = - 1;
                    stop = 0;
                elseif all(out_ORC.flag.value>0) && any(abs(out_ORC.res_vec) > 5e-5)
                    out_ORC.flag_ORC = -2;
                    stop = 0;
                else
                    out_ORC.flag_ORC = 1;
                    stop = 1;
                end
                if param.display
                    fprintf('%-60s %-60s %-10s %-100s \n', ['[' num2str(x.*ub,'%15.4e') ']'], [ num2str(out_ORC.res, '%.4g') '  [ ' num2str(out_ORC.res_vec,'%15.4e') ' ] '], num2str(out_ORC.flag_ORC), num2str(out_ORC.flag.value));
                end
                if out_ORC.res < out_ORC_best.res
                    out_ORC_best = out_ORC;
                end
                out_ORC = out_ORC_best;
                k = k+1;
            end
        else
            out_ORC.flag_ORC = - 1;
            TS_ORC = NaN;
        end
        
    end
    
    
    
end
out_ORC.time_ORC = toc(tstart_ORC);
if param.display
    fprintf('\n')
    dispstat('','keepprev')
end
out_ORC = orderfields(out_ORC);
if param.displayResults ==1 && out_ORC.flag_ORC == - 1
    dispstat('','keepprev')
    dispstat('Error: The model did not converge correctly','keepthis');
end


%% TS DIAGRAM and DISPLAY
if param.displayTS == 1
    figure
    hold all
    [~,~, ~] = Ts_diagram(TS_ORC, fluid_wf);
    hold off
    grid on
    xlabel('Entropy [J/kg.K]','fontsize',14,'fontweight','bold')
    ylabel('Temperature [�C]','fontsize',14,'fontweight','bold')
    set(gca,'fontsize',14,'fontweight','bold')
end

if param.displayResults ==1
    in.fluid_wf = fluid_wf;
    in.fluid_htf = fluid_htf;
    in.in_htf_su = in_htf_su;
    in.P_htf_su = P_htf_su;
    in.m_dot_htf = m_dot_htf;
    in.fluid_ctf = fluid_ctf;
    in.in_ctf_su = in_ctf_su;
    in.P_ctf_su = P_ctf_su;
    in.m_dot_ctf = m_dot_ctf;
    in.T_amb = T_amb;
    in.N_exp = N_exp;
    in.N_pp = N_pp;
    in.DT_sc = param.DT_sc;
    in.PP_modelType = param.PP.modelType;
    in.EV_modelType = param.EV.modelType;
    in.EXP_modelType = param.EXP.modelType;
    in.CD_modelType = param.CD.modelType;
    in.REC_modelType = param.REC.modelType;
    in.SUB_modelType = param.SUB.modelType;
    in.PRE_modelType = param.PRE.modelType;
    if nargin ==0
        fprintf ( 1, '\n' );
        disp('-------------------------------------------------------')
        disp('--------------------   Demo Code   --------------------')
        disp('-------------------------------------------------------')
        fprintf ( 1, '\n' );
    end
    disp('Working conditions:')
    fprintf ( 1, '\n' );
    disp(in)
    disp('Results:')
    disp(out_ORC)
end

end


function out = OrganicRankineCycle_init2(z, fluid_wf, fluid_htf, in_htf_su, T_htf_su, P_htf_su, m_dot_htf, fluid_ctf, in_ctf_su, T_ctf_su, P_ctf_su, m_dot_ctf, T_amb, N_exp, N_pp, param)
out.rp_pp = z(1)/z(2);
i_flag = 1;
i_mass = 1;

% PUMP
out.P_pp_su = z(2);
if strcmp(param.solverType, 'M_imposed')
    %     out.h_pp_su = (1-z(4))*CoolProp.PropsSI('H', 'P', out.P_pp_su, 'T', T_ctf_su-1, fluid_wf) + z(4)*CoolProp.PropsSI('H', 'P', out.P_pp_su, 'Q', 0, fluid_wf);
    out.h_pp_su = (1-z(4))*CoolProp.PropsSI('H', 'P', out.P_pp_su, 'T', T_ctf_su-1, fluid_wf) + z(4)*CoolProp.PropsSI('H', 'P', out.P_pp_su, 'T', CoolProp.PropsSI('T', 'P', out.P_pp_su, 'Q', 0, fluid_wf)-1, fluid_wf);
    out.T_pp_su = CoolProp.PropsSI('T', 'P', out.P_pp_su, 'Q', out.h_pp_su, fluid_wf) ;
    out.DT_sc = CoolProp.PropsSI('T', 'P', out.P_pp_su, 'Q', 0, fluid_wf)-out.T_pp_su;
elseif strcmp(param.solverType, 'DTsc_imposed')
    out.T_pp_su = CoolProp.PropsSI('T', 'P', out.P_pp_su, 'Q', 0, fluid_wf) - param.DT_sc;
    if param.DT_sc ~= 0
        out.h_pp_su = CoolProp.PropsSI('H', 'P', out.P_pp_su, 'T', CoolProp.PropsSI('T', 'P', out.P_pp_su, 'Q', 0, fluid_wf) - param.DT_sc, fluid_wf);
    else
        out.h_pp_su = CoolProp.PropsSI('H', 'P', out.P_pp_su, 'Q', 0, fluid_wf);
    end
    out.DT_sc = param.DT_sc;
end
[out_PP, ~] = PumpModel(out.P_pp_su, out.h_pp_su, z(1), fluid_wf, N_pp, param.PP);
out.M_pp = out_PP.M;
out.m_dot_wf = out_PP.m_dot;
out.W_dot_pp = out_PP.W_dot;
out.eps_is_pp = out_PP.epsilon_is;
out.eps_vol_pp = out_PP.epsilon_vol;
out.time_pp = out_PP.time;
out.flag_pp = out_PP.flag;

T_prev = out_PP.T_ex;
h_prev = out_PP.h_ex;
P_prev = z(1);

out.flag.value(1,i_flag) = out_PP.flag;
out.flag.name{1,i_flag} = 'flag_pp';
out.Mass.value(1,i_mass) = out_PP.M;
out.Mass.name{1,i_mass} = 'M_pp';

if isfield(param, 'V_aux_pp_ex') %Mass of fluid in the pipelines after the pump if volume specified
    i_mass = i_mass + 1;
    out.Mass.value(1,i_mass) = param.V_aux_pp_ex*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
    out.Mass.name{1,i_mass} = 'M_aux_pp_ex';
end

% LP LOSSES
if isfield(param, 'LossesLP')
    param.LossesLP.type_in = 'ex';
    [out_LossesLP_bis, ~] = LossesModel(fluid_wf, z(2), out.h_pp_su, out.m_dot_wf, T_amb, param.LossesLP);
    P_exp_ex = z(2)+out_LossesLP_bis.dp;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = out_LossesLP_bis.flag;
    out.flag.name{1,i_flag} = 'flag_dplp_bis';
    out.flag_LossesLP_bis = out_LossesLP_bis.flag;
else
    P_exp_ex = z(2);
end

% RECUPERATOR (cold side)
if isfield(param, 'REC')
    out.P_recc_su = P_prev;
    out.T_recc_su = out_PP.T_ex;
    out.h_recc_su = out_PP.h_ex;
    out.Q_dot_rec_max = HEX_Qdotmax(fluid_wf, out.m_dot_wf, P_exp_ex, CoolProp.PropsSI('H', 'P', P_exp_ex, 'T',T_htf_su, fluid_wf), fluid_wf, out.m_dot_wf, out.P_recc_su, out.h_recc_su, param.REC);
    out.Q_dot_rec_guess = z(3)*out.Q_dot_rec_max;
    h_prev = min(out.h_recc_su + out.Q_dot_rec_guess/out.m_dot_wf, CoolProp.PropsSI('H', 'P', out.P_recc_su, 'T', T_htf_su, fluid_wf));
    P_prev = out.P_recc_su;
    T_prev = CoolProp.PropsSI('T', 'P', P_prev, 'H', h_prev, fluid_wf);
    
    if isfield(param, 'V_aux_recc_ex') %Mass of fluid in the pipelines after the recuperator if volume specified
        i_mass = i_mass + 1;
        out.Mass.value(1,i_mass) = param.V_aux_recc_ex*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
        out.Mass.name{1,i_mass} = 'M_aux_recc_ex';
    end
    
end

% PREHEATER &/ EVAPORATOR
if isfield(param, 'PRE')
    out.P_pre_su = P_prev;
    out.T_pre_su = T_prev;
    out.h_pre_su = h_prev;
    pre_ev = HexSeries(fluid_htf, P_htf_su, in_htf_su, m_dot_htf, fluid_wf, out.P_pre_su, out.h_pre_su, out.m_dot_wf, param.PRE, param.EV);
    out.flag_pre_ev = pre_ev.flag;
    out.Q_dot_pre = pre_ev.hex1.Q_dot_tot;
    out.T_htf_pre_ex = pre_ev.hex1.T_h_ex;
    out.h_htf_pre_ex = pre_ev.hex1.h_h_ex;
    out.flag_pre = pre_ev.hex1.flag;
    out.pinch_pre = pre_ev.hex1.pinch;
    out.M_pre = pre_ev.hex1.M_c;
    out.time_pre = pre_ev.hex1.time;
    out.h_ev_su = pre_ev.hex1.h_c_ex;
    out.T_ev_su = pre_ev.hex1.T_c_ex;
    out.P_ev_su = out.P_pre_su;
    out.Q_dot_ev = pre_ev.hex2.Q_dot_tot;
    out.T_htf_ev_ex = pre_ev.hex2.T_h_ex;
    out.h_htf_ev_ex = pre_ev.hex2.h_h_ex;
    out.flag_ev = pre_ev.hex2.flag;
    out.pinch_ev = pre_ev.hex2.pinch;
    out.M_ev = pre_ev.hex2.M_c;
    out.time_ev = pre_ev.hex2.time;
    T_prev = pre_ev.hex2.T_c_ex;
    h_prev = pre_ev.hex2.h_c_ex;
    P_prev = out.P_ev_su;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = pre_ev.flag;
    out.flag.name{1,i_flag} = 'flag_pre_ev';
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = pre_ev.hex1.flag;
    out.flag.name{1,i_flag} = 'flag_pre';
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = pre_ev.hex2.flag;
    out.flag.name{1,i_flag} = 'flag_ev';
    
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_pre;
    out.Mass.name{1,i_mass} = 'M_pre';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_ev;
    out.Mass.name{1,i_mass} = 'M_ev';
else
    out.P_ev_su = P_prev;
    out.T_ev_su = T_prev;
    out.h_ev_su = h_prev;
    [out_EV, ~] = HexModel(fluid_htf, P_htf_su, in_htf_su, m_dot_htf, fluid_wf, out.P_ev_su, out.h_ev_su, out.m_dot_wf , param.EV);
    out.Q_dot_ev = out_EV.Q_dot_tot;
    out.T_htf_ev_ex = out_EV.T_h_ex;
    out.h_htf_ev_ex = out_EV.h_h_ex;
    out.M_ev = out_EV.M_c;
    out.flag_ev = out_EV.flag;
    out.time_ev = out_EV.time;
    out.pinch_ev = out_EV.pinch;
    P_prev = out.P_ev_su;
    T_prev = out_EV.T_c_ex;
    h_prev = out_EV.h_c_ex;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = out_EV.flag;
    out.flag.name{1,i_flag} = 'flag_ev';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_ev;
    out.Mass.name{1,i_mass} = 'M_ev';
    
end

% LossesHP
if isfield(param, 'LossesHP')
    out.P_dphp_su = P_prev;
    out.T_dphp_su = T_prev;
    out.h_dphp_su = h_prev;
    param.LossesHP.type_in = 'su';
    [out_LossesHP, ~] = LossesModel(fluid_wf, out.P_dphp_su, out.h_dphp_su, out.m_dot_wf, T_amb, param.LossesHP);
    out.dphp = out_LossesHP.dp;
    out.Q_dot_hp = out_LossesHP.Q_dot;
    T_prev = out_LossesHP.T_ex;
    h_prev = out_LossesHP.h_ex;
    P_prev = out_LossesHP.P_ex;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = out_LossesHP.flag;
    out.flag.name{1,i_flag} = 'flag_dphp';
    out.flag_LossesHP = out_LossesHP.flag;
    
    if isfield(param, 'V_aux_ev_ex') %Mass of fluid in the pipelines after the recuperator if volume specified
        i_mass = i_mass + 1;
        out.Mass.value(1,i_mass) = param.V_aux_ev_ex*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
        out.Mass.name{1,i_mass} = 'M_aux_ev_ex';
    end
end

% EXPANDER
out.P_exp_su = P_prev;
out.T_exp_su = T_prev;
out.h_exp_su = h_prev;
out.rp_exp = out.P_exp_su/P_exp_ex;
[out_EXP, ~] = ExpanderModel2(fluid_wf, out.P_exp_su, out.h_exp_su, out.m_dot_wf, P_exp_ex, T_amb, param.EXP);
out.N_exp_bis = out_EXP.N_exp;
out.W_dot_exp = out_EXP.W_dot;
out.Q_dot_exp = out_EXP.Q_dot_amb;
out.M_exp = out_EXP.M;
out.eps_vol_exp = out_EXP.FF;
out.eps_is_exp = out_EXP.epsilon_is;
out.flag_exp = out_EXP.flag;
out.time_exp = out_EXP.time;
T_prev = out_EXP.T_ex;
h_prev = out_EXP.h_ex;
P_prev = P_exp_ex;
i_flag = i_flag+1;
out.flag.value(1,i_flag) = out_EXP.flag;
out.flag.name{1,i_flag} = 'flag_exp';
i_mass = i_mass+1;
out.Mass.value(1,i_mass) = out.M_exp;
out.Mass.name{1,i_mass} = 'M_exp';
if isfield(param, 'V_aux_exp_ex') %Mass of fluid in the pipelines after the expander if volume specified
    i_mass = i_mass + 1;
    out.Mass.value(1,i_mass) = param.V_aux_exp_ex*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
    out.Mass.name{1,i_mass} = 'M_aux_exp_ex';
end


% RECUPERATOR (hot side)
if isfield(param, 'REC')
    out.P_rech_su = P_prev;
    out.T_rech_su = T_prev;
    out.h_rech_su = h_prev;
    [out_REC, ~] = HexModel(fluid_wf, out.P_rech_su, out.h_rech_su, out.m_dot_wf, fluid_wf, out.P_recc_su, out.h_recc_su, out.m_dot_wf, param.REC);
    out.Q_dot_rec = out_REC.Q_dot_tot;
    out.M_rech = out_REC.M_h;
    out.M_recc = out_REC.M_c;
    out.flag_rec = out_REC.flag;
    out.time_rec = out_EXP.time;
    out.pinch_rec = out_REC.pinch;
    h_prev = out_REC.h_h_ex;
    P_prev = out.P_rech_su;
    T_prev = out_REC.T_h_ex;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = out_REC.flag;
    out.flag.name{1,i_flag} = 'flag_rec';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_recc;
    out.Mass.name{1,i_mass} = 'M_recc';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_rech;
    out.Mass.name{1,i_mass} = 'M_rech';
    if isfield(param, 'V_aux_rech_ex') %Mass of fluid in the pipelines after the expander if volume specified
        i_mass = i_mass + 1;
        out.Mass.value(1,i_mass) = param.V_aux_rech_ex*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
        out.Mass.name{1,i_mass} = 'M_aux_rech_ex';
    end
end

% CONDENSER &/ SUBCOOLER
if isfield(param, 'SUB')
    out.P_cd_su = P_prev;
    out.T_cd_su = T_prev;
    out.h_cd_su = h_prev;
    sub_cd = HexSeries(fluid_wf, out.P_cd_su, out.h_cd_su, out.m_dot_wf, fluid_ctf, P_ctf_su, in_ctf_su, m_dot_ctf, param.SUB, param.CD);
    out.flag_sub_cd = sub_cd.flag;
    out.Q_dot_cd = sub_cd.hex2.Q_dot_tot;
    out.T_ctf_cd_ex = sub_cd.hex2.T_c_ex;
    out.h_ctf_cd_ex = sub_cd.hex2.h_c_ex;
    out.M_cd = sub_cd.hex2.M_h;
    out.flag_cd = sub_cd.hex2.flag;
    out.pinch_cd = sub_cd.hex2.pinch;
    out.time_cd = sub_cd.hex2.time;
    out.Q_dot_sub = sub_cd.hex1.Q_dot_tot;
    out.T_ctf_cd_su = sub_cd.hex1.T_c_ex;
    out.h_ctf_cd_su = sub_cd.hex1.h_c_ex;
    out.M_sub = sub_cd.hex1.M_h;
    out.flag_sub = sub_cd.hex1.flag;
    out.pinch_sub = sub_cd.hex1.pinch;
    out.time_sub = sub_cd.hex1.time;
    out.h_sub_su = sub_cd.hex2.h_h_ex;
    out.T_sub_su = sub_cd.hex2.T_h_ex;
    out.P_sub_su = out.P_cd_su;
    T_prev = sub_cd.hex1.T_h_ex;
    h_prev = sub_cd.hex1.h_h_ex;
    P_prev = out.P_sub_su;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = sub_cd.flag;
    out.flag.name{1,i_flag} = 'flag_sub_cd';
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = sub_cd.hex1.flag;
    out.flag.name{1,i_flag} = 'flag_sub';
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = sub_cd.hex2.flag;
    out.flag.name{1,i_flag} = 'flag_cd';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_cd;
    out.Mass.name{1,i_mass} = 'M_cd';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_sub;
    out.Mass.name{1,i_mass} = 'M_sub';
else
    out.P_cd_su = P_prev;
    out.T_cd_su = T_prev;
    out.h_cd_su = h_prev;
    [out_CD, ~] = HexModel(fluid_wf, out.P_cd_su, out.h_cd_su, out.m_dot_wf, fluid_ctf, P_ctf_su, in_ctf_su, m_dot_ctf , param.CD);
    out.Q_dot_cd = out_CD.Q_dot_tot;
    out.T_ctf_cd_ex = out_CD.T_c_ex;
    out.h_ctf_cd_ex = out_CD.h_c_ex;
    out.M_cd = out_CD.M_h;
    out.flag_cd = out_CD.flag;
    out.time_cd = out_CD.time;
    out.pinch_cd = out_CD.pinch;
    P_prev = out.P_cd_su;
    T_prev = out_CD.T_h_ex;
    h_prev = out_CD.h_h_ex;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = out_CD.flag;
    out.flag.name{1,i_flag} = 'flag_cd';
    i_mass = i_mass+1;
    out.Mass.value(1,i_mass) = out.M_cd;
    out.Mass.name{1,i_mass} = 'M_cd';
end

% LossesLP
if isfield(param, 'LossesLP')
    out.T_dplp_su = T_prev;
    out.h_dplp_su = h_prev;
    out.P_dplp_su = P_prev;
    param.LossesLP.type_in = 'su';
    [out_LossesLP, ~] = LossesModel(fluid_wf, out.P_dplp_su, out.h_dplp_su, out.m_dot_wf, T_amb, param.LossesLP);
    out.dplp = out_LossesLP.dp;
    out.Q_dot_lp = out_LossesLP.Q_dot;
    T_prev = out_LossesLP.T_ex;
    h_prev = out_LossesLP.h_ex;
    P_prev = out_LossesLP.P_ex;
    i_flag = i_flag+1;
    out.flag.value(1,i_flag) = out_LossesLP.flag;
    out.flag.name{1,i_flag} = 'flag_dplp';
    out.flag_LossesLP = out_LossesLP.flag;
end

% LIQUID RECEIVER AND PIPES
if isfield(param, 'V_aux_cd_ex') %Mass of fluid in the pipelines after the liquid receiver if volume specified
    i_mass = i_mass + 1;
    out.Mass.value(1,i_mass) = param.V_aux_cd_ex*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
    out.Mass.name{1,i_mass} = 'M_aux_cd_ex';
end
if isfield(param, 'V_liq_rec')
    if abs((h_prev-CoolProp.PropsSI('D','Q',0,'P',P_prev,fluid_wf))/h_prev)<1e-2
        i_mass = i_mass + 1;
        out.Mass.value(1,i_mass) = max(param.V_liq_rec*CoolProp.PropsSI('D','Q',1,'P',P_prev,fluid_wf),min(param.M_tot-sum(out.Mass.value),param.V_liq_rec*CoolProp.PropsSI('D','Q',0,'P',P_prev,fluid_wf)));
        out.Mass.name{1,i_mass} = 'M_liq_receiver';
    else
        i_mass = i_mass + 1;
        out.Mass.value(1,i_mass) = param.V_liq_rec*CoolProp.PropsSI('D','H',h_prev,'P',P_prev,fluid_wf);
        out.Mass.name{1,i_mass} = 'M_liq_receiver';
    end
end

out.M_tot = sum(out.Mass.value);

% RESIDUALS and RESULTS
out.res_ORC_Hsu = (1 - out.h_pp_su/h_prev);

out.res_ORC_N_exp = 1-out.N_exp_bis/N_exp;

if out.Q_dot_rec_guess == 0 && out.Q_dot_rec == 0
    out.res_ORC_Qdot_rec = 0;
elseif out.Q_dot_rec_guess == 0 && out.Q_dot_rec ~= 0
    out.res_ORC_Qdot_rec = 1;
elseif out.Q_dot_rec_guess ~= 0 && out.Q_dot_rec == 0
    out.res_ORC_Qdot_rec = 1;
else
    out.res_ORC_Qdot_rec = 1 - out.Q_dot_rec_guess/out.Q_dot_rec;
end

if strcmp(param.solverType, 'M_imposed')
    out.res_ORC_M = (1 - out.M_tot/param.M_tot);
    out.res_vec  = [out.res_ORC_N_exp    out.res_ORC_Hsu     out.res_ORC_Qdot_rec    out.res_ORC_M];
elseif strcmp(param.solverType, 'DTsc_imposed')
    out.res_vec  = [out.res_ORC_N_exp    out.res_ORC_Hsu     out.res_ORC_Qdot_rec];
    %out.res_vec  = [out.res_ORC_Hsu     out.res_ORC_Qdot_rec];
end

% if any(out.flag.value < 0)
%     out.res_vec  = 1e5*out.res_vec;
% end
out.res  = norm(out.res_vec);

out = orderfields(out);

end

function [c, c_eq] = mycon(x, ub, fluid_wf, T_htf_su, T_ctf_su, N_pp, param)
x = x.*ub;
P_pp_ex = x(1);
P_pp_su = x(2);
Q_dot_rec = x(3);
if strcmp(param.solverType, 'M_imposed')
    h_pp_su = x(4);
    h_pp_su_min = CoolProp.PropsSI('T', 'P', P_pp_su, 'T', T_ctf_su-10, fluid_wf);
    c(2) =  h_pp_su_min - h_pp_su;
elseif strcmp(param.solverType, 'DTsc_imposed')
    h_pp_su = CoolProp.PropsSI('H', 'P', P_pp_su, 'T', CoolProp.PropsSI('T', 'P', P_pp_su, 'Q', 0, fluid_wf) - param.DT_sc, fluid_wf);
end
[out_PP, ] = PumpModel(P_pp_su, h_pp_su, P_pp_ex, fluid_wf, N_pp, param.PP);
Q_dot_rec_max = HEX_Qdotmax(fluid_wf, out_PP.m_dot, P_pp_su, CoolProp.PropsSI('H', 'P', P_pp_su, 'T',T_htf_su, fluid_wf), fluid_wf, out_PP.m_dot, P_pp_ex, out_PP.h_ex, param.REC);
c(1) = Q_dot_rec-Q_dot_rec_max;
c_eq = [];
end

function [stop,options,optchanged] = outputfunPS(optimvalues,options,flag)
stop = optimvalues.fval < 1e-5;
optchanged = 0;
end

function stop = outputfunFS(x, optimValues, state)
%disp(norm(optimValues.fval))
stop = norm(optimValues.fval) < 5e-5;
end