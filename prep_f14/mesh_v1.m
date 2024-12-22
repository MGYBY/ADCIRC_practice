clearvars; clc; close all
% set(0,'defaultAxesFontSize',16);
% set(0,'DefaultFigurePaperPositionMode','auto')
% set(0,'defaultAxesFontName','CMU Serif')

% refined grid
% max_el = 2.5e3;
% min_el = 0.2e3;
% max_el_ns = 0.3e3;
% slp = 10;
% R_val = 3.0;
% grade_val = 0.25;

% regular grid
max_el = 8.25e3;
min_el = 0.3e3;
max_el_ns = 0.55e3;
slp = 9;
R_val = 3.0;
grade_val = 0.2;

% moderately coarse grid
% max_el = 14e3;
% min_el = 0.7e3;
% max_el_ns = 1.0e3;
% slp = 8;
% R_val = 3.0;
% grade_val = 0.2499;

% coarse grid
% max_el = 25e3;
% min_el = 0.79e3;
% max_el_ns = 0.8e3;
% slp = 8;
% R_val = 3.0;
% grade_val = 0.35;

dt_val = 2.0;

coastline = './GSHHS_l_L1';
nc_file = './dem_nc.nc';
bbox = [-80.05 -75.85; 43 44.4];
% gdat = geodata('shp', coastline, 'dem', nc_file, 'bbox', bbox, 'h0', min_el, 'inner', 1, 'mainland', 0);
gdat = geodata('shp', coastline, 'dem', nc_file, 'bbox', bbox, 'h0', min_el);

gdat.inpoly_flip = mod(1,gdat.inpoly_flip) ;

fh1 = edgefx('geodata', gdat, 'fs', R_val, 'max_el', max_el, 'dt', dt_val, 'g', grade_val, 'slp',slp);

mshopts = meshgen('ef',fh1,'bou',gdat,'plot_on',1,'nscreen',5,'proj','trans');
mshopts = mshopts.build;
m = mshopts.grd;

% m = make_bc(m,'auto',gdat,'distance'); % make the boundary conditions
plot(m,'type','tri');

m = interp(m,gdat, 'type', 'depth' ,'mindepth',0.2); % interpolate bathy to the mesh with minimum depth of 1 m
CFL = CalcCFL(m,dt_val);
max(CFL)
min(CFL)
m = bound_courant_number(m,dt_val);

%% Make the nodestring boundary conditions
% m = make_bc(m,'auto',gdat,'distance');
m = make_bc(m,'auto',gdat);

%% Identify vstart and vend of each riverine boundary
% use the comannd-line method to identify the vstart and vend for each...
% riverine boundary based on the coordinates of river edge.
% FIXME: this feature for OBC does not work now
% river_points1 = [-76.4769295622357	44.2303880817742; -76.4302272383152	44.2032579224691]; % coordinates of river edge
% river_points2 = [-76.3775332218752	44.1496325877826; -76.3410690849980	44.1289194788211]; % coordinates of river edge
% bc_k1 = ourKNNsearch(m.p',river_points1',1);
% bc_k2 = ourKNNsearch(m.p',river_points2',1);
% m = make_bc(m,'outer',1,bc_k1(1),bc_k1(2),1,4);
% m = make_bc(m,'outer',1,bc_k2(1),bc_k2(2),1,4);

% use the data cursor method to identify the vstart and vend for each...
% riverine boundary manually (GUI).
% m = make_bc(m,'outer',1); % 1,2206,2107,1(flux),22(River)
% m = make_bc(m,'outer',1); % 1,14784,14779,1(flux),22(River)

m = renum(m);

plot(m,'type','bd');

plot(m,'type','b');   % plot bathy on native projection

%% Export plots
figs = get(0,'children');
for f = 1:numel(figs)
    fname = sprintf('plot%i', figs(f).Number);
    print(figs(f).Number,fname,'-djpeg','-r700');
end

%% Save mesh files
% Save as a msh class
% save(sprintf('%s_msh.mat',PREFIX),'m');
% % Write an ADCIRC fort.14 compliant file to disk.
write(m, 'lo_mesh')
