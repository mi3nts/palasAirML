
function [] = palasDataImport(yamlFile)
    
    %UNTITLED Summary of this function goes here
    display(newline)
    display("---------------------MINTS---------------------")

    addpath("../../functions/")

    addpath("YAMLMatlab_0.4.3")
    mintsDefinitions  = ReadYaml(yamlFile)

    dataFolder          = mintsDefinitions.dataFolder;
    driveReferenceLabel = mintsDefinitions.driveReferenceLabel;
    timeSpan            = seconds(mintsDefinitions.timeSpan);

    folderCheck(dataFolder) 
    referenceFolder         = dataFolder + "/reference";
    referenceMatsFolder     = dataFolder + "/referenceMats";
    palasFolder             = referenceFolder       + "/palasStream";
    palasMatsFolder         = referenceMatsFolder   + "/palas";
    airMarMatsFolder        = referenceMatsFolder   + "/airmar";
    driveSyncFolder         = strcat(dataFolder,"/exactBackUps/palasStream/");

    display(newline)
    display("Data Folder Located @:"+ dataFolder)
    display("Reference Data Located @: "+ referenceFolder )
    display("Reference DotMat Data Located @ :"+ referenceMatsFolder)
    display("Palas Raw Data Located @ :"+ palasFolder)
    display("Palas DotMat Data Located @ :"+ palasMatsFolder)
    display("Google Drive Reference Label :"+ driveSyncFolder)

    %% Syncing Process
    display(newline)
    display("---------------------MINTS---------------------")
    display("MINTS Syncing")
    syncFromCloudPalas(driveReferenceLabel,palasFolder,driveSyncFolder)

    palasFiles       = dir(palasFolder+"/*.txt");

    %% Concatinating Process
    display(newline)
    display("---------------------MINTS---------------------")
    display("Concatinating Palas Data")

    parfor fileIndex = 1: length(palasFiles)
            fileName            = strcat(palasFiles(fileIndex).folder,"/",palasFiles(fileIndex).name);
            S{fileIndex}        = palasStreamRead(fileName,timeSpan);
            palasStreamHeights(fileIndex) = height(S{fileIndex});
    end


    evalString = " palasStreamAll = ["  
    for fileIndex = 1:length(palasFiles)
        if(palasStreamHeights(fileIndex)>0)
            evalString = strcat(evalString,"S{",string(fileIndex),"};");
        end
    end 

    evalString = strcat(evalString,"];");
    display(evalString);
    eval(evalString);

    %% Saving Data 
    display(newline)
    display("---------------------MINTS---------------------")
    palasStream    = unique(palasStreamAll);

    saveNameStream      = strcat(palasMatsFolder,"/palasStream.mat");
    folderCheck(saveNameStream)

    display("Saving Palas Stream Data as : "+saveNameStream)
    save(saveNameStream,'palasStream');

    palasStream(:,7:end)=[];

    display("Loading Old Palas Data")
    load(strcat(palasFolder,"/palasFinal_08_22_2020.mat"))
    palasDataNow.Properties.VariableNames= {'pm1_palas',...
                                            'pm2_5_palas',...
                                            'pm4_palas'  ,...
                                            'pm10_palas' ,...
                                            'pmTotal_palas',...
                                            'dCn_palas' };
    % Retiming with old data  
    display("Retiming with Old Palas Data")
    palas  = retime(sortrows([palasStream; palasDataNow]),'regular',@mean,'TimeStep',timeSpan);
    saveNamePalas      = strcat(palasMatsFolder,"/palas.mat");
    folderCheck(saveNamePalas)

    display("Saving Palas Data as : "+saveNamePalas)
    save(saveNamePalas ,'palas');

end

