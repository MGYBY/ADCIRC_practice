% This code converts ECMWF ERA Interim wind field data (including 10 m u-wind velocity/ 10 m v-wind velocity/ Mean sea level pressure) from netcdf format to DHI MIKE dfs2 format
% Written by Mostafa Nazarali (2017-05-02)
% mostafa.nazarali@gmail.com

clear all;
clc

fn=dir('2019-10-28_11-3.nc');
fname1=fn.name;
u=ncread(fname1,'e');
v=ncread(fname1,'tp');
% p=ncread(fname1,'sp');
lat=ncread(fname1,'latitude');
lon=ncread(fname1,'longitude');
t=ncread(fname1,'valid_time');
t=datenum(2019,10,29,23,0,0)+double(t)/24;

delete './ECMWF_5.txt'

fid=fopen('ECMWF_5.txt','wt');
% Titels
fprintf(fid,'"Title" "File Title"\n');
fprintf(fid,'"Dim" 2\n');
fprintf(fid,'"Geo" "LONG/LAT" %d %d 0\n',length(lon),length(lat));
fprintf(fid,'"Time" "EqudistantTimeAxis" "%s" "%s" %d %d\n',datestr(t(1),'yyyy-mm-dd'),datestr(t(1),'HH:MM:SS'),length(t),(t(2)-t(1))/24/3600);
fprintf(fid,'"NoGridPoints" %d %d\n',length(lon),length(lat));
fprintf(fid,'"Spacing" %g %g\n',abs(lon(2)-lon(1)),abs(lat(2)-lat(1)));
fprintf(fid,'"NoStaticItems" 0\n');
fprintf(fid,'"NoDynamicItems" 2\n');
fprintf(fid,'"Item" "Evaporation" "Evaporation Rate" "mm/h"\n');
fprintf(fid,'"Item" "Total precipitation" "Precipitation Rate" "mm/h"\n');
% fprintf(fid,'"Item" "V-wind" "Wind Velocity" "m/s"\n');
fprintf(fid,'NoCustomBlocks 1\n');
fprintf(fid,'"M21_Misc" 1 7 0 -1E-030 -900 -999 -1E-030 -1E-030 -1E-030\n');
fprintf(fid,'"Delete" -1E-030\n');
fprintf(fid,'"DataType" 0\n');
fprintf(fid,'\n');
for i=1:length(t)
    i
    fprintf(fid,'"tstep" %d "item" 1 "layer" 0\n',i-1);
    for j=1:length(lat)
    % for j=length(lat):-1:1
        for k=1:length(lon)
        % for k=length(lon):-1:1
            fprintf(fid,'%f ',(u(k,j,i)*(-1000.0)));
        end
        fprintf(fid,'\n');
    end
    fprintf(fid,'\n');
    fprintf(fid,'"tstep" %d "item" 2 "layer" 0\n',i-1);
    for j=1:length(lat)
    % for j=length(lat):-1:1
        for k=1:length(lon)
        % for k=length(lon):-1:1
            fprintf(fid,'%f ',(v(k,j,i)*1000.0));
        end
        fprintf(fid,'\n');
    end
    fprintf(fid,'\n');
    % fprintf(fid,'"tstep" %d "item" 3 "layer" 0\n',i-1);
    % for j=1:length(lat)
    % % for j=length(lat):-1:1
    %     for k=1:length(lon)
    %     % for k=length(lon):-1:1
    %         fprintf(fid,'%f ',(v(k,j,i)));
    %     end
    %     fprintf(fid,'\n');
    % end
    % fprintf(fid,'\n');    
end
fclose(fid);