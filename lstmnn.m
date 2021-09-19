%%
clc;clear;
warning off;
%% ��������
%% 
data = xlsread('data.xlsx','A2:D2000');
% ��������
input =data(:,1:3)';
output=data(:,4)';
nwhole =size(data,1);
train_ratio=0.9;
ntrain=round(nwhole*train_ratio);
ntest =nwhole-ntrain;
% ׼����������ѵ������
input_train =input(:,1:ntrain);
output_train=output(:,1:ntrain);
% ׼����������
input_test =input(:, ntrain+1:ntrain+ntest);
output_test=output(:,ntrain+1:ntrain+ntest);


%% ��һ����ȫ������ ����һ����
[inputn_train,inputps]  =mapminmax(input_train);
[outputn_train,outputps]=mapminmax(output_train);
inputn_test =mapminmax('apply',input_test,inputps); 
outputn_test=mapminmax('apply',output_test,outputps); 
%% LSTM �����ã���������
inputSize  = size(inputn_train,1);   %��������x������ά��
outputSize = size(outputn_train,1);  %�������y��ά��  
numhidden_units1=60;
numhidden_units2=180;
numhidden_units3=60;
%% lstm
layers = [ ...
    sequenceInputLayer(inputSize)                 %���������
    lstmLayer(numhidden_units1,'name','hidden1')  %ѧϰ������(cell�㣩
    dropoutLayer(0.2,'name','dropout_1')
    lstmLayer(numhidden_units2,'Outputmode','sequence','name','hidden2') 
    dropoutLayer(0.3,'name','dropout_2')
    lstmLayer(numhidden_units3,'name','hidden3') 
    dropoutLayer(0.2,'name','dropout_3')
    fullyConnectedLayer(outputSize)               % ȫ���Ӳ����ã�Ӱ�����ά�ȣ�
    regressionLayer('name','out')];
%% trainoption(lstm)
opts = trainingOptions('adam', ...
    'MaxEpochs',200, ...
    'GradientThreshold',1,...
    'ExecutionEnvironment','cpu',...
    'InitialLearnRate',0.005, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',100, ...                % epoch��ѧϰ�ʸ���
    'LearnRateDropFactor',0.8, ...
    'Verbose',0, ...
    'Plots','training-progress'... 
    );

%% LSTM����ѵ��
tic
LSTMnet = trainNetwork(inputn_train ,outputn_train ,layers,opts);
toc;
[LSTMnet,LSTMoutputr_train]= predictAndUpdateState(LSTMnet,inputn_train);
LSTMoutput_train = mapminmax('reverse',LSTMoutputr_train,outputps);
%% LSTM��������
%%
%����������
[LSTMnet,LSTMoutputr_test] = predictAndUpdateState(LSTMnet,inputn_test);
%�����������һ��
LSTMoutput_test= mapminmax('reverse',LSTMoutputr_test,outputps);
%% LSTM�������
%%
%-------------------------------------------------------------------------------------
error_test=LSTMoutput_test'-output_test';
pererror_test=error_test./output_test';
error=error_test';
pererror=pererror_test';
avererror=sum(abs(error))/(ntest);
averpererror=sum(abs(pererror))/(ntest);
RMSE = sqrt(mean((error).^2));
disp('LSTM����Ԥ�����ƽ�����MAE');
disp(avererror);
disp('LSTM����Ԥ��ƽ���������ٷֱ�MAPE');
disp(averpererror)
disp('LSTM����Ԥ����������RMSE')
disp(RMSE)

%% LSTM���ݿ��ӻ�����
%��������
figure()
plot(LSTMoutput_test,'r:.')     
hold on
plot(output_test,'k--')           
legend( 'Ԥ���������','ʵ�ʷ�������','Location','NorthWest','FontName','����');
%title('LSTM����ģ�ͽ������ʵֵ','fontsize',12,'FontName','����')
xlabel('ʱ��(s)','fontsize',12,'FontName','����');
ylabel('����������״̬Ԥ��(h)','fontsize',12,'FontName','����');
%-------------------------------------------------------------------------------------
figure()
stairs(pererror_test,'-.','Color',[255 50 0]./255,'linewidth',0.7)        
legend('LSTM�������������','Location','NorthEast','FontName','����')
%title('LSTM����Ԥ��������','fontsize',12,'FontName','����')
ylabel('������','fontsize',12,'FontName','����')
xlabel('��������','fontsize',12,'FontName','����')
%-------------------------------------------------------------------------------------

