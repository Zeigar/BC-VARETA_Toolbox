classdef BC_VARETA_guide < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        BCVARETAToolboxv10UIFigure  matlab.ui.Figure
        FileMenu                    matlab.ui.container.Menu
        DownloadtestdataMenu        matlab.ui.container.Menu
        ImportdataMenu              matlab.ui.container.Menu
        ExitMenu                    matlab.ui.container.Menu
        ToolsMenu                   matlab.ui.container.Menu
        CreateDataStructureMenu     matlab.ui.container.Menu
        LeadFieldComputationMenu    matlab.ui.container.Menu
        SingleSubjectMenu_LF        matlab.ui.container.Menu
        BatchProcessingMenu_LF      matlab.ui.container.Menu
        MEEGAnalysisMenu            matlab.ui.container.Menu
        SingleSubjectMenu_A         matlab.ui.container.Menu
        BatchProcessingMenu_A       matlab.ui.container.Menu
        ViewMenu                    matlab.ui.container.Menu
        FigureMenu                  matlab.ui.container.Menu
        SubjectsresultMenu          matlab.ui.container.Menu
        SubjectsconnectivityMenu    matlab.ui.container.Menu
        SubjectsactivityMenu        matlab.ui.container.Menu
        RealEEGMenu                 matlab.ui.container.Menu
        HelpMenu                    matlab.ui.container.Menu
        TextArea                    matlab.ui.control.TextArea
    end

    
    properties (Access = private)
        Property % Description
    end
    
    properties (Access = public)
        single_subject % Description
    end
    
    methods (Access = private)
        
        function setPromptFcn(app,jTextArea,eventData,newPrompt)
            % Prevent overlapping reentry due to prompt replacement
            persistent inProgress
            if isempty(inProgress)
                inProgress = 1;  %#ok unused
            else
                return;
            end
            
            try
                % *** Prompt modification code goes here ***
                cwText = char(jTextArea.getText);
                app.TextArea.Value = cwText;
                % force prompt-change callback to fizzle-out...
                pause(0.02);
            catch
                % Never mind - ignore errors...
            end
            
            % Enable new callbacks now that the prompt has been modified
            inProgress = [];
            
        end  % setPromptFcn
        
    end
    

    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            clc;
            processes = jsondecode(fileread(strcat('app_processes.json')));
            for i = 1: length(processes)
                process = processes(i);
                if(process.active)
                    addpath(process.root_folder);
                end
            end
            try
                jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
                jCmdWin = jDesktop.getClient('Command Window');
                jTextArea = jCmdWin.getComponent(0).getViewport.getView;
                set(jTextArea,'CaretUpdateCallback',@app.setPromptFcn)
            catch
                warndlg('fatal error');
            end
        end

        % Menu selected function: CreateDataStructureMenu
        function CreateDataStructureMenuSelected(app, event)
            folder = uigetdir('tittle','Select the Source Folder');
            if(folder==0)
                return;
            end
            create_data_structure(folder);
            msgbox('Completed operation!!!','Info');
        end

        % Callback function
        function ButtonPushed(app, event)
            jDesktop = com.mathworks.mde.desk.MLDesktop.getInstance;
            jCmdWin = jDesktop.getClient('Command Window');
            jTextArea = jCmdWin.getComponent(0).getViewport.getView;
            cwText = char(jTextArea.getText);
            
            set(jTextArea,'CaretUpdateCallback',@myUpdateFcn)
            
        end

        % Menu selected function: ExitMenu
        function ExitMenuSelected(app, event)
            delete(app);
        end

        % Menu selected function: DownloadtestdataMenu
        function DownloadtestdataMenuSelected(app, event)
            folder = uigetdir('tittle','Select the Source Folder');
            if(folder==0)
                return;
            end
            
            f = dialog('Position',[300 300 250 80]);
            
            iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
            iconsSizeEnums = javaMethod('values',iconsClassName);
            SIZE_32x32 = iconsSizeEnums(2);  % (1) = 16x16,  (2) = 32x32
            jObj = com.mathworks.widgets.BusyAffordance(SIZE_32x32, 'Downloading test data...');  % icon, label
            
            jObj.setPaintsWhenStopped(true);  % default = false
            jObj.useWhiteDots(false);         % default = false (true is good for dark backgrounds)
            javacomponent(jObj.getComponent, [50,10,150,80], f);
            jObj.start;
            pause(1);
            
            app_properties= jsondecode(fileread(strcat('app_properties.json')));
            url = app_properties.generals.test_data_url;
            filename = strcat(folder,filesep,'BC_VARETA_test_data.zip');
            matlab.net.http.HTTPOptions.VerifyServerName = false;
            options = weboptions('Timeout',Inf,'RequestMethod','get');
            
            try
                disp('Downloding test data....');
                outfilename = websave(filename,url,options);
            catch
                delete(f);
                errordlg('Download error!!!','Error');
                return;
            end
            try
                disp('Unpacking test data....');
                exampleFiles = unzip(filename,folder);
            catch
                delete(f);
                errordlg('Unpackage error!!!','Error');
                return;
            end
            jObj.stop;
            jObj.setBusyText('All done!');
            disp('All done....');
            pause(2);
            delete(f);
            msgbox('Download complete','Info');
        end

        % Menu selected function: FigureMenu
        function FigureMenuSelected(app, event)
            
            [file,path] = uigetfile('*.fig');
            if isequal(file,0)
                disp('User selected Cancel');
                return;
            end
            openfig(strcat(path,filesep,file));
        end

        % Menu selected function: SubjectsresultMenu
        function SubjectsresultMenuSelected(app, event)
            folder = uigetdir('tittle','Select the Source Folder');
            if(folder==0)
                return;
            end
            files = dir(folder);
            ext='.fig';
            for j=1:size(files,1)
                file_name = files(j).name;
                file_path = strcat(folder,filesep, file_name);
                [~,name,ex]=fileparts(file_name);
                %% ----------Searching de data files ------------------------------------
                if(~isfolder(file_path) & strcmpi(strtrim(ex),ext) )
                    openfig(strcat(file_path));
                end
            end
        end

        % Menu selected function: RealEEGMenu
        function RealEEGMenuSelected(app, event)
            %             [file,path] = uigetfile('*.mat');
            %             if isequal(file,0)
            %                 disp('User selected Cancel');
            %                 return;
            %             end
            %             real_EEG=load(strcat(path,filesep,file));
            %
            %             figure_EEG = figure('Color','k','Name',file,'NumberTitle','off','units','normalized','outerposition',[0 0 1 1]);
            %             subplot(1,3,1); plot(real_EEG.Sjj);
            %             %             ylabel('generators')
            %             %     xlabel('generators')
            %             %     title('simulated partial correlations')
            %             subplot(1,3,2); plot(real_EEG.Thetajj);
            %             %             ylabel('generators')
            %             %     xlabel('generators')
            %             %     title('simulated partial correlations')
            %             subplot(1,3,3); plot(real_EEG.indms);
            
        end

        % Menu selected function: SingleSubjectMenu_A
        function SingleSubjectMenu_ASelected(app, event)
            addpath('functions');
            bcv_properties = jsondecode(fileread(strcat('bcv_properties.json')));
            bcv_properties.run_single_subject.value = true;
            saveJSON(bcv_properties,strcat('properties',filesep,'bcv_properties.json'));
            BC_VARETA_bash;
            msgbox('Completed operation!!!','Info');
        end

        % Menu selected function: BatchProcessingMenu_A
        function BatchProcessingMenu_ASelected(app, event)
            bcv_properties = jsondecode(fileread(strcat('bcv_properties.json')));
            bcv_properties.run_single_subject.value = false;
            saveJSON(bcv_properties,strcat('properties',filesep,'bcv_properties.json'));
            BC_VARETA_bash;
            msgbox('Completed operation!!!','Info');
        end

        % Menu selected function: SingleSubjectMenu_LF
        function SingleSubjectMenu_LFSelected(app, event)
            addpath('bst_lf_ppl');
            bs_lf_ppl;
            msgbox('Completed operation!!!','Info');
        end

        % Menu selected function: BatchProcessingMenu_LF
        function BatchProcessingMenu_LFSelected(app, event)
            addpath('bst_lf_ppl');
            bs_lf_ppl;
            msgbox('Completed operation!!!','Info');
        end

        % Menu selected function: SubjectsconnectivityMenu
        function SubjectsconnectivityMenuSelected(app, event)
            folder = uigetdir('tittle','Select the Subject''s result folder');
            if(folder==0)
                return;
            end
            files = dir(folder);
            ext='.fig';
            for j=1:size(files,1)
                file_name = files(j).name;
                file_path = strcat(folder,filesep, file_name);
                [~,name,ex]=fileparts(file_name);
                %% ----------Searching de data files ------------------------------------
                if(~isfolder(file_path) & strcmpi(strtrim(ex),ext) & contains(file_name,'roi_conn'))
                    openfig(strcat(file_path));
                end
            end
        end

        % Menu selected function: SubjectsactivityMenu
        function SubjectsactivityMenuSelected(app, event)
            folder = uigetdir('tittle','Select the Subject''s result folder');
            if(folder==0)
                return;
            end
            files = dir(folder);
            ext='.fig';
            for j=1:size(files,1)
                file_name = files(j).name;
                file_path = strcat(folder,filesep, file_name);
                [~,name,ex]=fileparts(file_name);
                %% ----------Searching de data files ------------------------------------
                if(~isfolder(file_path) & strcmpi(strtrim(ex),ext) & contains(file_name,'activity') )
                    openfig(strcat(file_path));
                end
            end
        end

        % Menu selected function: ImportdataMenu
        function ImportdataMenuSelected(app, event)
            import_data_structure;
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create BCVARETAToolboxv10UIFigure
            app.BCVARETAToolboxv10UIFigure = uifigure;
            app.BCVARETAToolboxv10UIFigure.Color = [0.9412 0.9412 0.9412];
            app.BCVARETAToolboxv10UIFigure.Colormap = [0.2431 0.149 0.6588;0.251 0.1647 0.7059;0.2588 0.1804 0.7529;0.2627 0.1961 0.7961;0.2706 0.2157 0.8353;0.2745 0.2353 0.8706;0.2784 0.2549 0.898;0.2784 0.2784 0.9216;0.2824 0.302 0.9412;0.2824 0.3216 0.9569;0.2784 0.3451 0.9725;0.2745 0.3686 0.9843;0.2706 0.3882 0.9922;0.2588 0.4118 0.9961;0.2431 0.4353 1;0.2196 0.4588 0.9961;0.1961 0.4863 0.9882;0.1843 0.5059 0.9804;0.1804 0.5294 0.9686;0.1765 0.549 0.9529;0.1686 0.5686 0.9373;0.1529 0.5922 0.9216;0.1451 0.6078 0.9098;0.1373 0.6275 0.898;0.1255 0.6471 0.8902;0.1098 0.6627 0.8745;0.0941 0.6784 0.8588;0.0706 0.6941 0.8392;0.0314 0.7098 0.8157;0.0039 0.7216 0.7922;0.0078 0.7294 0.7647;0.0431 0.7412 0.7412;0.098 0.749 0.7137;0.1412 0.7569 0.6824;0.1725 0.7686 0.6549;0.1922 0.7765 0.6235;0.2157 0.7843 0.5922;0.2471 0.7922 0.5569;0.2902 0.7961 0.5176;0.3412 0.8 0.4784;0.3922 0.8039 0.4353;0.4471 0.8039 0.3922;0.5059 0.8 0.349;0.5608 0.7961 0.3059;0.6157 0.7882 0.2627;0.6706 0.7804 0.2235;0.7255 0.7686 0.1922;0.7725 0.7608 0.1647;0.8196 0.749 0.1529;0.8627 0.7412 0.1608;0.902 0.7333 0.1765;0.9412 0.7294 0.2118;0.9725 0.7294 0.2392;0.9961 0.7451 0.2353;0.9961 0.7647 0.2196;0.9961 0.7882 0.2039;0.9882 0.8118 0.1882;0.9804 0.8392 0.1765;0.9686 0.8627 0.1647;0.9608 0.8902 0.1529;0.9608 0.9137 0.1412;0.9647 0.9373 0.1255;0.9686 0.9608 0.1059;0.9765 0.9843 0.0824];
            app.BCVARETAToolboxv10UIFigure.Position = [100 100 679 459];
            app.BCVARETAToolboxv10UIFigure.Name = 'BC-VARETA Toolbox v1.0';

            % Create FileMenu
            app.FileMenu = uimenu(app.BCVARETAToolboxv10UIFigure);
            app.FileMenu.Text = 'File';

            % Create DownloadtestdataMenu
            app.DownloadtestdataMenu = uimenu(app.FileMenu);
            app.DownloadtestdataMenu.MenuSelectedFcn = createCallbackFcn(app, @DownloadtestdataMenuSelected, true);
            app.DownloadtestdataMenu.Text = 'Download test data';

            % Create ImportdataMenu
            app.ImportdataMenu = uimenu(app.FileMenu);
            app.ImportdataMenu.MenuSelectedFcn = createCallbackFcn(app, @ImportdataMenuSelected, true);
            app.ImportdataMenu.Text = 'Import data';

            % Create ExitMenu
            app.ExitMenu = uimenu(app.FileMenu);
            app.ExitMenu.MenuSelectedFcn = createCallbackFcn(app, @ExitMenuSelected, true);
            app.ExitMenu.Text = 'Exit';

            % Create ToolsMenu
            app.ToolsMenu = uimenu(app.BCVARETAToolboxv10UIFigure);
            app.ToolsMenu.Text = 'Tools';

            % Create CreateDataStructureMenu
            app.CreateDataStructureMenu = uimenu(app.ToolsMenu);
            app.CreateDataStructureMenu.MenuSelectedFcn = createCallbackFcn(app, @CreateDataStructureMenuSelected, true);
            app.CreateDataStructureMenu.Text = 'Create Data Structure';

            % Create LeadFieldComputationMenu
            app.LeadFieldComputationMenu = uimenu(app.ToolsMenu);
            app.LeadFieldComputationMenu.Text = 'Lead Field Computation';

            % Create SingleSubjectMenu_LF
            app.SingleSubjectMenu_LF = uimenu(app.LeadFieldComputationMenu);
            app.SingleSubjectMenu_LF.MenuSelectedFcn = createCallbackFcn(app, @SingleSubjectMenu_LFSelected, true);
            app.SingleSubjectMenu_LF.Text = 'Single Subject';

            % Create BatchProcessingMenu_LF
            app.BatchProcessingMenu_LF = uimenu(app.LeadFieldComputationMenu);
            app.BatchProcessingMenu_LF.MenuSelectedFcn = createCallbackFcn(app, @BatchProcessingMenu_LFSelected, true);
            app.BatchProcessingMenu_LF.Text = 'Batch Processing';

            % Create MEEGAnalysisMenu
            app.MEEGAnalysisMenu = uimenu(app.ToolsMenu);
            app.MEEGAnalysisMenu.Text = 'MEEG Analysis';

            % Create SingleSubjectMenu_A
            app.SingleSubjectMenu_A = uimenu(app.MEEGAnalysisMenu);
            app.SingleSubjectMenu_A.MenuSelectedFcn = createCallbackFcn(app, @SingleSubjectMenu_ASelected, true);
            app.SingleSubjectMenu_A.Text = 'Single Subject';

            % Create BatchProcessingMenu_A
            app.BatchProcessingMenu_A = uimenu(app.MEEGAnalysisMenu);
            app.BatchProcessingMenu_A.MenuSelectedFcn = createCallbackFcn(app, @BatchProcessingMenu_ASelected, true);
            app.BatchProcessingMenu_A.Text = 'Batch Processing';

            % Create ViewMenu
            app.ViewMenu = uimenu(app.BCVARETAToolboxv10UIFigure);
            app.ViewMenu.Text = 'View';

            % Create FigureMenu
            app.FigureMenu = uimenu(app.ViewMenu);
            app.FigureMenu.MenuSelectedFcn = createCallbackFcn(app, @FigureMenuSelected, true);
            app.FigureMenu.Text = 'Figure';

            % Create SubjectsresultMenu
            app.SubjectsresultMenu = uimenu(app.ViewMenu);
            app.SubjectsresultMenu.MenuSelectedFcn = createCallbackFcn(app, @SubjectsresultMenuSelected, true);
            app.SubjectsresultMenu.Text = 'Subject''s result';

            % Create SubjectsconnectivityMenu
            app.SubjectsconnectivityMenu = uimenu(app.ViewMenu);
            app.SubjectsconnectivityMenu.MenuSelectedFcn = createCallbackFcn(app, @SubjectsconnectivityMenuSelected, true);
            app.SubjectsconnectivityMenu.Text = 'Subject''s connectivity';

            % Create SubjectsactivityMenu
            app.SubjectsactivityMenu = uimenu(app.ViewMenu);
            app.SubjectsactivityMenu.MenuSelectedFcn = createCallbackFcn(app, @SubjectsactivityMenuSelected, true);
            app.SubjectsactivityMenu.Text = 'Subject''s activity';

            % Create RealEEGMenu
            app.RealEEGMenu = uimenu(app.ViewMenu);
            app.RealEEGMenu.MenuSelectedFcn = createCallbackFcn(app, @RealEEGMenuSelected, true);
            app.RealEEGMenu.Text = 'Real EEG ';

            % Create HelpMenu
            app.HelpMenu = uimenu(app.BCVARETAToolboxv10UIFigure);
            app.HelpMenu.Text = 'Help';

            % Create TextArea
            app.TextArea = uitextarea(app.BCVARETAToolboxv10UIFigure);
            app.TextArea.Position = [29 21 625 391];
        end
    end

    methods (Access = public)

        % Construct app
        function app = BC_VARETA_guide

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.BCVARETAToolboxv10UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.BCVARETAToolboxv10UIFigure)
        end
    end
end