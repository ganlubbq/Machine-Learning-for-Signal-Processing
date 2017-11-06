%% 
%load data
folder = '/Users/youzhedou/Desktop/Code_samples/Machine-Learning-for-Signal-Processing/HW2/Data/Train/';
listname = dir([folder '*.txt']);
L=length(listname);
all_data = cell(24,3);
nl = ones(24,1);
for i = 1: L
    all_data{i,1} = load(['/Users/youzhedou/Desktop/Code_samples/Machine-Learning-for-Signal-Processing/HW2/Data/Train/Class_' num2str(i) '.txt']);
    all_data{i,2} = load(['/Users/youzhedou/Desktop/Code_samples/Machine-Learning-for-Signal-Processing/HW2/Data/DEV/Class_' num2str(i) '.txt']);
    all_data{i,3} = load(['/Users/youzhedou/Desktop/Code_samples/Machine-Learning-for-Signal-Processing/HW2/Data/Eval/Class_' num2str(i) '.txt']);
    nl(i) = size(all_data{i,1},1);
end
%% Q1
% Normalizing the length of all I-vectors x
normalized_data = all_data;
for i = 1:L
    for j = 1:size(all_data,2)
        [r,c] =size(all_data{i,j});
        for k = 1 : r
            norm1 = norm(all_data{i,j}(k,:));
            normalized_data{i,j}(k,:) = all_data{i,j}(k,:) ./ norm1;
        end
    end
end

%% 
% LDA 
I_vectors = [];%all I-vectors
for i = 1 :L
    I_vectors = [I_vectors;normalized_data{i,1}];
end
w_mean = mean(I_vectors,1);
wl = zeros(L,c);
Sb = zeros(c,c);
Sw = zeros(c,c);
%Sb
for i = 1:L
    wl(i,:) = mean(normalized_data{i,1},1);
    diff = wl(i,:)-w_mean;
    Sb = Sb + nl(i)*(diff'*diff);
end
%Sw
for i = 1 :L
    for j = 1 : nl(i)
        diff=normalized_data{i,1}(j,:)-wl(i,:);
        Sw = Sw + diff'* diff;
    end
end
%compute eigen vector
[V,D] = eigs(Sb,Sw,L-1);
%%
% Training
for i = 1 : L 
    sz = size(normalized_data{i,1});
    for k = 1 :sz(1)
        %project i-vectors
        w = (normalized_data{i,1}(k,:))';
        data_proj{i,1}(k,:) = V'* w/(norm(V'* w));
    end
end
for i = 1 : L 
    %compute mean and normalise length
    Mat{i,1} = 1/sz(1) * sum(data_proj{i,1},1) / (norm(1/sz(1) * sum(data_proj{i,1},1)));
end
% Testing
w_test = cell(24,3);
for i = 2:3
    for j = 1:L
        sz = size(normalized_data{j,i});
        for k = 1:sz(1)
            w = (normalized_data{j,i}(k,:))';
            w_test{j,i}(k,:) = V'* w/ norm(V' * w);
        end
    end
end 
sample_score = cell(24,3);
for i = 2:3
    for j = 1:L
        sz = size(normalized_data{j,i});
        for k = 1 :sz(1)
            for r = 1:L
                m1 = w_test{j,i}(k,:);
                m2 = Mat{r,1};
                sample_score{j,i}(k,r) = dot(m1,m2);
            end
            [I,b] = max(sample_score{j,i}(k,:));
            lan_class{i,j}(k,1) = b;
        end
    end
end
[acc_dev1, acc_eval1 ] = testAcc(lan_class);
%%
% Question 2
A=[];%A=[D1,D2...D24]
for i = 1 :L 
    A = horzcat(A,(all_data{i,1})');
end
for i = 2:3
    for j = 1:L
        sz = size(all_data{j,i});
        for k = 1:sz(1)
            x = all_data{j,i}(k,:);
            %new weights from Lasso
            new_weights{j,i}(k,:) = SolveBP(A, x', size(A,2),10,1,1e-3);
            index = 1;
            for c = 1 : L
                alpha{c} = new_weights{j,i}(k,index:index+nl(c)-1);
                index = index+nl(c);
            end
            for c = 1 :L
                D = all_data{c,1};
                recon_data = alpha{c}*D;
                recon_error_2{j,i}(c,1) = norm(x-recon_data,2);
            end
            [M,I] = min(recon_error_2{j,i});
            lan_class{j,i}(k,1) = I;
        end
    end
end
[ acc_dev2, acc_eval2 ] = testAcc(lan_class);
%% 
% Question 3
for i = 2:3
    for j = 1 : L 
        sz = size(w_test{j,i});
        for k = 1 :sz(1)
            x = w_test{j,i}(k,:);
            new_weights{j,i}(k,:) = SolveBP(V'*A/norm(V'*A), x',size(A,2),10,1,1e-3);
            index = 1;
            for r = 1 : L
                alpha{r} = new_weights{j,i}(k,index:index+nl(r)-1);
                index = index+nl(r);
            end
            for r = 1 :L
                D = (V'*all_data{r,1}'/norm(V'*all_data{r,1}'))';
                recon_data=alpha{r}*D;
                recon_error_3{j,i}(r,1) = norm(x - recon_data,2);
            end
            [M,I] = min(recon_error_3{j,i});
            lan_class{j,i}(k,1) = I;
        end
    end
end
[ acc_dev3, acc_eval3] = testAcc(lan_class);
%% 
% Question 4
% take 55 centeroids
for i = 1: L
    if size(all_data{i,1},1) == 55
      data_kmean{i,1} = all_data{i,1};
    else
     [idx,data_kmean{i,1}] = kmeans(all_data{i,1},55);
    end
end
A=[];
for i = 1 :L 
    A = horzcat(A,(data_kmean{i,1})');
end
for i = 2:3
    for j = 1 : 24 
        [h,g] = size(w_test{j,i});
        for k = 1 :h
            x = w_test{j,i}(k,:);
            new_weights{j,i}(k,:) = SolveBP(V'*A/norm(V'*A), x', L*55,10,1,1e-3);
            index = 1;
            for r = 1 : L
                alpha{r} = new_weights{j,i}(k,index:index+55-1);
                index = index+55;
            end
            for r = 1 :L
                D = (V'*data_kmean{r,1}'/norm(V'*data_kmean{r,1}'))';
                recon_data = alpha{r}*D;
                recon_error_4{j,i}(r,1) = norm(x - recon_data,2);
            end
            [M,I] = min(recon_error_4{j,i});
            lan_class{j,i}(k,1) = I;
        end
    end
end
[ acc_dev4, acc_eval4] = testAcc(lan_class);
%% 
% Question 5
class_mean=cell(1,L);
covv=cell(1,L);
shared_cov=zeros(c,c);
for i =1:L
    class_mean{i}=mean(all_data{i,1},1);
    covv{i}=cov(all_data{i,1});
    shared_cov=shared_cov + (size(all_data{i,1},1)/22491)*covv{i};
end
sample_score_d=zeros(2400,L);
data_dev=[];
for i =1:L
    data_dev = [data_dev;all_data{i,2}];
end
for i =1:24
    sample_score_d(:,i)= mvnpdf(data_dev,class_mean{i},shared_cov);
end
[M,I] = max(sample_score_d,[],2);
acc_d=0;
for i =1:2400
    if I(i)==ceil(i/100)
        acc_d=acc_d+1;
    end
end
acc_d=acc_d/2400;
sample_score_e=zeros(2400,24);
data_evl=[];
for i =1:24
    data_evl = [data_evl;all_data{i,3}];
end
for i =1:24
    sample_score_e(:,i)= mvnpdf(data_evl,class_mean{i},shared_cov);
end
[M,I] = max(sample_score_e,[],2);
acc_e=0;
for i =1:2400
    if I(i)==round(i/100)
        acc_e=acc_e+1;
    end
end
acc_e=acc_e/2400;
acc_5=[acc_d,acc_e];