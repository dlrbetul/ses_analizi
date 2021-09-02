%% Parametreler
clear; clc;
DataEgitimKlasor='DataEgitim';
DataTestKlasor='DataTest';
DosyaSinifBilgileri='DosyaİsimVeSiniflari.xlsx';

%% Dosyalar hakkında bilgilerin okunması
[Sinif,Text] = xlsread(DosyaSinifBilgileri);
Dosyalar=Text(2:end,1);
Tur=Text(2:end,2);

SesDosyaMinBoyut=minBoyutBul(DataEgitimKlasor,DataTestKlasor,Dosyalar,Tur);
clear Text DosyaSinifBilgileri

%% YSA Eğitim Aşaması

% Verilerin ayrıştırılması
mask=strcmpi(Tur,'Eğitim');
EgitimDosya=Dosyalar(mask);
EgitimSinif=Sinif(mask);
EgitimGiris=GirisDataCagir(DataEgitimKlasor,EgitimDosya,SesDosyaMinBoyut);
EgitimCikis=CikisDataCagir(EgitimSinif);
clear mask

% 1. eğitim
ysaNet1 = patternnet(5);
ysaNet1.trainParam.showWindow=false;
ysaNet1 = train(ysaNet1,EgitimGiris,EgitimCikis);
y1 = ysaNet1(EgitimGiris);
ysaNetCikis=ysaCikisSinifAta(y1);
Tutarlilik1=TutarlilikHesap(EgitimCikis,ysaNetCikis);

% 2. eğitim
ysaNet2 = patternnet(5);
ysaNet2.trainParam.showWindow=false;
ysaNet2 = train(ysaNet2,EgitimGiris,EgitimCikis);
y2 = ysaNet2(EgitimGiris);
ysaNetCikis=ysaCikisSinifAta(y2);
Tutarlilik2=TutarlilikHesap(EgitimCikis,ysaNetCikis);

% Optimum YSA network seçimi
ysaNet=ysaNet1;
if Tutarlilik2>Tutarlilik1, ysaNet=ysaNet2; end
clear y1 y2 ysaNet1 ysaNet2 EgitimGiris EgitimCikis Tutarlilik1 Tutarlilik2 ysaNetCikis

%% GUI

 % Create a UI figure window
 fig = uifigure;
 % Create a record object
 recObj = audiorecorder;
 % Create a UI axes
 
 lmp = uilamp('Parent',fig,...
             'Position',[380, 198, 30, 30],...
             'Color', [1 0 0]);   
 % Create a push button for recording
 btnRecord = uibutton(fig,'push',...
                     'Position',[420, 218, 100, 22],...
                     'ButtonPushedFcn', @(btnRecord,event) RecButtonPushed(btnRecord,lmp));
 btnRecord.Text = 'Record';
 % Create a playback button
 btnPlay = uibutton(fig, 'push', ...
                    'Position', [420, 188, 100, 22], ...
                    'ButtonPushedFcn', @(btnPlay,event) PlayButtonPushed(btnPlay,ysaNet,SesDosyaMinBoyut));
 btnPlay.Text = 'Tahmin';                   
 
 % Create the function for the RecordButtonPushedFcn callback
 function RecButtonPushed(btnRecord,lmp)
         %sesi mikrofondan aldığımız yer
            lmp.Color = [0 1 0];
            audioObject = audiorecorder;
            recordblocking(audioObject, 5);
            lmp.Color = [1 0 0];
            %ses kaydını durduruyoruz
            assignin('base','audioObject',audioObject);
            %sesi audioObject'e atıyoruz.
            y = getaudiodata(audioObject);
            Fs = audioObject.SampleRate;
            %sesi test dosyasına kaydediyoruz
            audiowrite('DataTest\test.wav',y,Fs);
 end
 % Create the function for the PlayButtonPushedFcn callback
 function PlayButtonPushed(btnPlay,ysaNet,SesDosyaMinBoyut)
            
            A=audioread('DataTest\test.wav');
            B = reshape(A,SesDosyaMinBoyut,1);
            yy = ysaNet(B);
            ysaNetCikis=ysaCikisSinifAta(yy);
            if ysaNetCikis(1)==1, Tahmin=msgbox('Başkasının sesi'); end
            if ysaNetCikis(1)==0, Tahmin=msgbox('Senin sesin'); end
            
 end
%% GUI Sonu

function SesDosyaMinBoyut=minBoyutBul(DataEgitimKlasor,DataTestKlasor,Dosyalar,Tur)

% Eğitim dosayaları
mask=strcmpi(Tur,'Eğitim');
D=Dosyalar(mask);
m=0;
for j=1:length(D)
    A=audioread(fullfile(DataEgitimKlasor,D{j}));
    if ~isempty(A)
        m=m+1;
        Boyut1(m,1)=size(A,1);
    end
end

% Test dosyaları
mask=strcmpi(Tur,'Test');
D=Dosyalar(mask);
m=0;
for j=1:length(D)
    if isfile(fullfile(DataTestKlasor,D{j}))
        m=m+1;
        A=audioread(fullfile(DataTestKlasor,D{j}));
        Boyut2(m,1)=size(A,1);
    end
end
Boyut=[Boyut1; Boyut2];
SesDosyaMinBoyut=min(Boyut);
end % function end

function DataGiris=GirisDataCagir(DataKlasor,Dosyalar,SesDosyaMinBoyut)

for j=1:length(Dosyalar)
    A=audioread(fullfile(DataKlasor,Dosyalar{j}));
    DataGiris(:,j)=A(1:SesDosyaMinBoyut,1);
end
end % function end

function Cikis = CikisDataCagir(EgitimSinif)
% Cikis = [ Başkası Kendisi]
Cikis=zeros(2,length(EgitimSinif));
EgitimSinif=EgitimSinif';
mask=EgitimSinif==1;
Cikis(2,:)=EgitimSinif;
Cikis(1,:)=double(~mask);
end % function end

function ysaNetCikis = ysaCikisSinifAta(y)
ysaNetCikis=zeros(size(y));
for j=1:size(y,2)
    [~,m]=max(y(:,j));
    ysaNetCikis(m,j)=1;
end
end % function end

function Tutarlilik = TutarlilikHesap(EgitimCikis,ysaNetCikis)
Isabet=zeros(1,size(EgitimCikis,2));
for j=1:size(EgitimCikis,2)
    if isequal(EgitimCikis(:,j),ysaNetCikis(:,j))
        Isabet(j)=1;
    end
end
Tutarlilik=sum(Isabet)/numel(Isabet);
end % function end





