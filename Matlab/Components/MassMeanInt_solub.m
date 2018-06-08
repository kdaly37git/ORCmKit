function [M_rv, M_rl, M_lub, M_ref, M_liq, M_vap, M_mix, alpha_mean] = MassMeanInt_solub(T_K_1, P_Pa_1, zeta_r_1, C_rv_1, Tbubble_min_1, Tsat_pure_1, T_K_2, P_Pa_2, zeta_r_2, C_rv_2, Tbubble_min_2, Tsat_pure_2, V, fluid_r, fluid_lub, fit_ratio_rho, param)
  
%compute  flow densities
[rho_vap_1, ~, ~, rho_liq_1, ~] = R245fa_POE_density(T_K_1, P_Pa_1, zeta_r_1, fluid_r, fluid_lub, fit_ratio_rho, Tbubble_min_1, Tsat_pure_1);
[rho_vap_2, ~, ~, rho_liq_2, ~] = R245fa_POE_density(T_K_2, P_Pa_2, zeta_r_2, fluid_r, fluid_lub, fit_ratio_rho, Tbubble_min_2, Tsat_pure_2);
rho_vap_mean = 0.5*rho_vap_1 + 0.5*rho_vap_2;
rho_liq_mean = 0.5*rho_liq_1 + 0.5*rho_liq_2;
zeta_r_mean = 0.5*zeta_r_1+0.5*zeta_r_2;

if 0.5*C_rv_1 + 0.5*C_rv_2 > 0 %there is a vapour phase
    alpha_mean = VoidFraction_Integration(C_rv_1, C_rv_2, rho_vap_mean, rho_liq_mean, param);
else % there is no vapour phase
    alpha_mean = 0;
end

M_rv = V*alpha_mean*rho_vap_mean;
M_rl = V*(1-alpha_mean)*zeta_r_mean*rho_liq_mean;
M_lub = V*(1-alpha_mean)*(1-zeta_r_mean)*rho_liq_mean;
M_ref = M_rl + M_rv;
M_liq = M_rl + M_lub;
M_vap = M_rv;
M_mix = M_ref + M_lub;

end
