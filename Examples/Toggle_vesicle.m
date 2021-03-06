%% 25/09/2017 Miroslav Gasparek
% Script for modeling communication in liposome sensor-reporter system in
% BioSIMI modeling toolbox
% Sample for single vesicle with toggle switch

%%
function Toggle_vesicle(aTc_conc,IPTG_conc,time_aTc)

%     aTc_conc = 1500;
%     IPTG_conc = 1000;
%     time_aTc = '0.1*60*60';
% time_eval = char(num2str(eval(time_aTc)/(60*60)));
    %% Reporter vesicle with toggle switch
    % Initially aTc with concentration of 1000 nM is added
    % Initial internal concentration of IPTG is 0
    % IPTG diffuses into vesicle and causes the change of states of the switch
    % define plasmid concentration
    ptet_DNA = 4; % nM
    placI_DNA = 1; % nM

    % set up the tubes
    tube1 = txtl_extract('E30VNPRL');
    tube2 = txtl_buffer('E30VNPRL');
    tube3 = txtl_newtube('genetics_switch');

    % add dna to tube3
    dna_lacI = txtl_add_dna(tube3,'ptet(50)', 'utr1(20)', 'lacI(647)', ptet_DNA, 'plasmid');
    dna_tetR = txtl_add_dna(tube3, 'plac(50)', 'utr1(20)', 'tetR(647)', placI_DNA, 'plasmid');
    dna_deGFP = txtl_add_dna(tube3, 'ptet(50)', 'rbs(20)', 'deGFP(1000)', ptet_DNA, 'plasmid');
    dna_deCFP = txtl_add_dna(tube3, 'placI(50)', 'rbs(20)', 'deCFP(1000)', placI_DNA, 'plasmid');

    % combine extact, buffer and dna into one tube
    Toggle = txtl_combine([tube1, tube2, tube3]);

    % add inducers
    txtl_addspecies(Toggle, 'aTc',0);
    txtl_addspecies(Toggle, 'IPTG',IPTG_conc);

    %% Create Toggle Subsystem
    Toggle_Subsystem = BioSIMI_make_subsystem(Toggle,'aTc','protein deGFP*','Toggle_Subsystem')
    Toggle = BioSIMI_assemble(Toggle_Subsystem,'Toggle')

    FacDiffOut = BioSIMI_make_subsystem('FacDiffOut','input','output','FacDiffOut')
    rename(FacDiffOut.ModelObject.Species(1),'protein deGFP* inside')
    rename(FacDiffOut.ModelObject.Species(3),'protein deGFP* (exported)')
    vesicle_system = BioSIMI_connect_new_object('vesicle',{'int','ext'},Toggle,FacDiffOut,'vesicle_system')

    DiffIn = BioSIMI_make_subsystem('DiffusionIn','input','output','DiffIn')
    rename(DiffIn.ModelObject.Species(1),'aTcIN')
    rename(DiffIn.ModelObject.Species(2),'aTcOUT')

    BioSIMI_add_subsystem(vesicle_system.ModelObject,{'int','ext'},DiffIn)

    ToggleSystem = BioSIMI_connect(vesicle_system.ModelObject,'int',DiffIn,vesicle_system,'ToggleSystem')
    e1 = addevent(ToggleSystem.ModelObject,['time>=',time_aTc],['DiffIn_aTcOUT = ',num2str(aTc_conc)])

    simdata = BioSIMI_runsim(ToggleSystem,8*60*60)
    BioSIMI_plot(ToggleSystem,simdata,'Toggle_IPTG')
    %%
    figHandles = findobj('Type', 'figure');
    for i = 1:size(figHandles,1)
        figHandles(i).CurrentAxes.Title.String = {figHandles(i).CurrentAxes.Title.String,['extracellular aTc = ',num2str(aTc_conc),' nM, t_{add}aTc = ',char(num2str(eval(time_aTc)/(60*60))),' h, IPTG = ',num2str(IPTG_conc),' nM']};
        allaxes(i) = findall(figHandles(i), 'type', 'axes');
        allaxes(i).YLim = [0 2000];
    end
    saveas(gcf,['Toggle_vesicle,t_aTc = ',char(num2str(eval(time_aTc)/(60*60))),' h.png'])

end