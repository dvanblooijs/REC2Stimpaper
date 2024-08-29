%% visualisation of specific electrodes
% This function renders a brain surface with Destrieux maps

function renderBrainwElecs(myDataPath,cfg,session)
%%
if contains(fieldnames(cfg),'transparency')
    transparency = cfg.transparency;
else
    transparency = 1;
end

cmap = parula(3);

% pick a viewing angle:
viewDirs = [0,0;... % back
    -45,0;... % back_left
    45,0;... % back_right
    -90,-90;... % bottom
    0,-45;... % bottom_back
    180,-45;... % bottom_front
    -90,-45;... % bottom_left
    90,-45;... % bottom_right
    180,0;... %front
    -135,0;... % front_left
    135,0;... % front_right
    -90,0;... %left
    90,0;... % right
    -90,90;... % top
    0,45;... % top_back
    180,45;...% top_front
    -90,45;... %top_left
    90,45]; % top_right

fig_pos = {'back','back_left','back_right',...
    'bottom','bottom_back','bottom_front','bottom_left','bottom_right',...
    'front','front_left','front_right',...
    'left','right',...
    'top','top_back','top_front','top_left','top_right'};
%%

FSfiles = dir(fullfile(myDataPath.dataPath,'derivatives','surfaces',cfg.sub_label,session{1},...
    [cfg.sub_label,'_', session{1},'_T1w']));
idx = [FSfiles(:).isdir] == 0;

% gifti file name:
dataGiiName = fullfile(FSfiles(idx).folder,FSfiles(idx).name);
% load gifti:
g = gifti(dataGiiName);

elecmatrix_all = cell(size(session));
tb_elecs_all = cell(size(session));
for nSes = 1:size(session,2)
  
    tb_elecs = readtable(fullfile(myDataPath.dataPath, cfg.sub_label,session{nSes},'ieeg',...
        [cfg.sub_label '_', session{nSes}, '_electrodes.tsv']),'FileType','text','Delimiter','\t');

    % electrode locations name:
    idx_elec_incl = ~strcmp(tb_elecs.group,'other');
    tb_elecs = tb_elecs(idx_elec_incl,:);
    if iscell(tb_elecs.x)
        elecmatrix = [str2double(tb_elecs.x) str2double(tb_elecs.y) str2double(tb_elecs.z)];
    else
        elecmatrix = [tb_elecs.x tb_elecs.y tb_elecs.z];
    end

    elecmatrix_all{nSes} = elecmatrix;
    tb_elecs_all{nSes} = tb_elecs;
end


%% figure with rendering for different viewing angles
for nView = 1:size(viewDirs,1) % loop across viewing angles
    viewDir = viewDirs(nView,:);
    
    figure('Name',fig_pos{nView},'units','normalized','position',[0.01 0.01 0.9 0.9],'color',[1 1 1]);
       
    setLight = 1;
    ecog_RenderGifti(g,transparency,setLight); % render       
    ecog_ViewLight(viewDir(1),viewDir(2)) % change viewing angle
    
    hold on
    for nSes = 1:size(session,2)

        elecmatrix = elecmatrix_all{nSes};

        a_offset = 0.1*max(abs(elecmatrix(:,1)))*[cosd(viewDir(1)-90)*cosd(viewDir(2)) sind(viewDir(1)-90)*cosd(viewDir(2)) sind(viewDir(2))];
        els = elecmatrix+repmat(a_offset,size(elecmatrix,1),1);

        % add electrode numbers
        if strcmp(cfg.show_labels,'yes')
            tb_elecs = tb_elecs_all{nSes};
            ecog_Label(els,tb_elecs.name,50,12) % [electrodes, electrode labels, MarkerSize, FontSize]
        end

        if strcmp(session{nSes},'ses-1')
            ccep_el_add(els,[1 1 1],100) % white layer 
            ccep_el_add(els,cmap(1,:),90) % [electrodes, MarkerColor, MarkerSize]

        elseif strcmp(session{nSes},'ses-2')
            ccep_el_add(els,[1 1 1],100) % white layer 
            ccep_el_add(els,cmap(2,:),90) % [electrodes, MarkerColor, MarkerSize]

        else
            ccep_el_add(els,[1 1 1],100) % white layer 
            ccep_el_add(els,[1 0 1],90) % [electrodes, MarkerColor, MarkerSize]
            
        end
    end

    set(gcf,'PaperPositionMode','auto')
    
    if strcmp(cfg.save_fig, 'yes')
        if ~exist(fullfile(myDataPath.Figures,'rendering',cfg.sub_label),'dir')
           mkdir( fullfile(myDataPath.Figures,'rendering',cfg.sub_label))
        end
        
        fileName = sprintf('rendering_%s_%s.png',fig_pos{nView},horzcat(session{:}));

        saveas(gcf,fullfile(myDataPath.Figures,'rendering',cfg.sub_label,fileName))

        fprintf('File %s is saved \n',fullfile(myDataPath.Figures,'rendering',cfg.sub_label,fileName))
    end
end
