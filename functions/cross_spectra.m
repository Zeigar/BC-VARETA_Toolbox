function [Svv_channel,K_6k,PSD,Nf,F,Nseg] = cross_spectra(data,Fs,Fm,deltaf,K_6k,Nw)


% Authors:
% - Deirel Paz Linares
% - Eduardo Gonzalez Moreira
% - Pedro A. Valdes Sosa

% Date: March 16, 2019

% Updates
% - Ariosky Areces Gonzalez

% Date: March 18, 2019

%% estimating cross-spectra...
[Svv_channel,F,Nseg,PSD] = xspectrum(data,Fs,Fm,deltaf,Nw);                 % estimates the Cross Spectrum of the input M/EEG data
disp('applying average reference...');
Nf = length(F);
for jj = 1:Nf
    [Svv_channel(:,:,jj),K_6k] = applying_reference(Svv_channel(:,:,jj),K_6k);    % applying average reference...
end
%%

end

