% test real data, MHAD as example

clear; close all;

rootPath = '~/research/code/OutlierCleaning';
addpath(genpath(fullfile(rootPath, 'SupervisedCleaning/xk')));
addpath(genpath(fullfile(rootPath, '3rdParty')));

dataPath = '~/research/data/MHAD';
load(fullfile(dataPath, 'MHAD_data_fps22.mat'));
np = 35;

%% load testing data, add synthetic outliers
ysTest = data{label_sub==2 & label_act==11 & label_rep==1};
gtJoint = ysTest;
[d, n] = size(ysTest);
rng('default');
% rng(5);
% nOutlier = round(0.3 * size(ysTest, 2));
nOutlier = 10;
xMin = min(min(ysTest(1:3:end,:)));
xMax = max(max(ysTest(1:3:end,:)));
yMin = min(min(ysTest(2:3:end,:)));
yMax = max(max(ysTest(2:3:end,:)));
zMin = min(min(ysTest(3:3:end,:)));
zMax = max(max(ysTest(3:3:end,:)));
for i = 1:np
%     index = randi(n, 1, nOutlier);
    start = randi(n-nOutlier+1);
    index = (start:start+nOutlier-1);
    ysTest((i-1)*3+1,index) = xMin + (xMax-xMin)*rand(1,nOutlier);
    ysTest((i-1)*3+2,index) = xMin + (xMax-xMin)*rand(1,nOutlier);
    ysTest((i-1)*3+3,index) = xMin + (xMax-xMin)*rand(1,nOutlier); 
end

%% outlier cleaning
lambda = 20;
lambda1 = 20;
lambda2 = 1e10;
ysClean = zeros(size(ysTest));
for i = 1:size(ysTest, 1)
% for i = 19
    fprintf('Performing SRPCA on Joint %d/%d\n', i, size(ysTest, 1));
    y = ysTest(i, :);
    [omega, residue, cnt] = outlierDetectionS2R3(y);
    yHat = minRankL2Admm(y, lambda, omega);
%     yHat = l2_fastalm_mo(y, lambda, 'omega', omega);
%     yHat = SRPCA_e1_e2_clean_md(y', lambda1, lambda2, ones(size(y')));
    yHat = yHat';
    ysClean(i, :) = yHat;
%     figure(1);
%     plot(y, 'x-');
%     hold on;
%     plot(yHat, 'o-');
%     title(sprintf('Test Instance %d',i));
%     hold off;
%     pause;
end
e = ysClean-ysTest;
norm(e)

%%
thres = 10;
acc = computeAccuracy3d(ysClean, gtJoint, thres);
%% plot acc curve with 
[accVectorSrpca, aucSrpca] = plotAccCurve3d(ysClean, gtJoint);
aucSrpca
save(fullfile(rootPath,'expData','accVectorSrpca3d'), 'accVectorSrpca', 'aucSrpca');
