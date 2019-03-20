function [result] = band_analysis(Svv,K_6k,F,band,parameters_data,figures)


elect_58_343 = parameters_data.elect_58_343;
ASA_343 = parameters_data.ASA_343;
S_h = parameters_data.S_h;
cmap_a=parameters_data.cmap_a;
cmap_c=parameters_data.cmap_c;
Nseg=parameters_data.Nseg;
S_6k=parameters_data.S_6k;



peak_pos=parameters_data.peak_pos;


%% inverse covariance matrix...
Nelec = size(K_6k,1);
Svv_inv = sqrt(Svv*Svv+4*eye(Nelec))-Svv;
%%

%% electrodes space visualization...
X = zeros(length(elect_58_343.conv_ASA343),1);
Y = zeros(length(elect_58_343.conv_ASA343),1);
Z = zeros(length(elect_58_343.conv_ASA343),1);
for ii = 1:length(elect_58_343.conv_ASA343)
    X(ii) = ASA_343.Channel(elect_58_343.conv_ASA343{ii}).Loc(1);
    Y(ii) = ASA_343.Channel(elect_58_343.conv_ASA343{ii}).Loc(2);
    Z(ii) = ASA_343.Channel(elect_58_343.conv_ASA343{ii}).Loc(3);
end
C = abs(diag(Svv));
C = C/max(C);
C(C<0.01) = 0;
figure_scalp = figure('Color','k'); hold on; set(gca,'Color','k');
scatter3(X,Y,Z,100,C.^1,'filled');
patch('Faces',S_h.Faces,'Vertices',S_h.Vertices,'FaceVertexCData',0.01*(ones(length(S_h.Vertices),1)),'FaceColor','interp','EdgeColor','none','FaceAlpha',.35);
colormap(gca,cmap_a);
az = 0; el = 0;
view(az, el);
title('Scalp','Color','w','FontSize',16);


figures.figure_scalp = figure_scalp;


temp_diag  = diag(diag(abs(Svv_inv)));
temp_ndiag = abs(Svv_inv)-temp_diag;
temp_ndiag = temp_ndiag/max(temp_ndiag(:));
temp_diag  = diag(abs(diag(Svv)));
temp_diag  = temp_diag/max(temp_diag(:));
temp_diag  = diag(diag(temp_diag)+1);
temp_comp  = temp_diag+temp_ndiag;
figure_scalp_electrodes = figure('Color','k');
imagesc(temp_comp);
set(gca,'Color','k','XColor','w','YColor','w','ZColor','w',...
    'XTick',1:length(elect_58_343.conv_ASA343),'YTick',1:length(elect_58_343.conv_ASA343),...
    'XTickLabel',elect_58_343.label,'XTickLabelRotation',90,...
    'YTickLabel',elect_58_343.label,'YTickLabelRotation',0);
xlabel('electrodes','Color','w');
ylabel('electrodes','Color','w');
colormap(gca,cmap_c);
colorbar;
axis square;
title('Scalp','Color','w','FontSize',16);

figures.figure_scalp_electrodes = figure_scalp_electrodes;

pause(1e-12);
%%
%% bc-vareta toolbox...
%% Parameters
param.maxiter_outer = 60;
param.maxiter_inner = 30;
param.m             = length(peak_pos)*Nseg;
param.penalty       = 1;
param.rth           = 3.16;
param.axi           = 1E-3;
param.Axixi         = eye(length(Svv));
%%
%% Activation Leakage Module
disp('activation leakage module...');
% Default Atlas (groups)
nonovgroups = [];
for ii = 1:length(K_6k)
    nonovgroups{ii} = ii;
end
%%
[miu,sigma_post,DSTF] = cross_nonovgrouped_enet_ssbl({Svv},{K_6k},length(peak_pos)*Nseg,nonovgroups);
stat                  = sqrt((abs(miu))./abs(sigma_post));
indms                 = find(stat > 1);
%%
%% Connectivity Leakage Module
disp('connectivity leakage module...');
[ThetaJJ,SJJ,llh,jj_on,xixi_on] = h_hggm(Svv,K_6k(:,indms),param);
%%
%% Plotting results
sources_iv          = zeros(length(K_6k),1);
sources_iv(indms)   = abs(diag(SJJ));
sources_iv          = sources_iv/max(sources_iv(:));
ind_zr              = sources_iv < 0.01;
sources_iv(ind_zr)  = 0;
figure_BC_VARETA = figure('Color','k'); hold on;
patch('Faces',S_6k.Faces,'Vertices',S_6k.Vertices,'FaceVertexCData',sources_iv,'FaceColor','interp','EdgeColor','none','FaceAlpha',.85);
set(gca,'Color','k');
az = 0; el = 0;
view(az,el);
colormap(gca,cmap_a);
title('BC-VARETA','Color','w','FontSize',16);

figures.figure_BC_VARETA1 = figure_BC_VARETA1;

temp_iv    = abs(SJJ);
connect_iv = abs(ThetaJJ);
temp       = abs(connect_iv);
temp_diag  = diag(diag(temp));
temp_ndiag = temp-temp_diag;
temp_ndiag = temp_ndiag/max(temp_ndiag(:));
temp_diag  = diag(abs(diag(temp_iv)));
temp_diag  = temp_diag/max(temp_diag(:));
temp_diag  = diag(diag(temp_diag)+1);
temp_comp  = temp_diag+temp_ndiag;
label_gen = [];
for ii = 1:length(indms)
    label_gen{ii} = num2str(ii);
end
figure_BC_VARETA2 = figure('Color','k');
imagesc(temp_comp);
set(gca,'Color','k','XColor','w','YColor','w','ZColor','w',...
    'XTick',1:length(indms),'YTick',1:length(indms),...
    'XTickLabel',label_gen,'XTickLabelRotation',90,...
    'YTickLabel',label_gen,'YTickLabelRotation',0);
xlabel('sources','Color','w');
ylabel('sources','Color','w');
colorbar;
colormap(gca,cmap_c);
axis square;
title('BC-VARETA','Color','w','FontSize',16);

figures.figure_BC_VARET2 = figure_BC_VARETA2;

pause(1e-12);

%% saving...

save(strcat(pathname ,'/EEG_real_',band(3),'_',band(1),'Hz-',band(1),'Hz.mat'),'ThetaJJ','SJJ','indms');

for i=1:numel(fields)
    saveas(fields(i),strcat(pathname ,'/',get(fields(i),'title'))) ;
end

end
