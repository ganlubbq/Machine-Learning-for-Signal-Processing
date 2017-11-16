%% Load Data
train_image = loadMNISTImages('data/train-images-idx3-ubyte');
labels = loadMNISTLabels('data/train-labels-idx1-ubyte');
[D,N]=size(train_image);
mu=sum(train_image,2)/N;
train_image_centralised=train_image-mu*ones(1,N);
X = train_image_centralised;
%% 
accuracy=[];
for K = 50:50:100
    W = randn(D,K);
    sigma = abs(randn(1,1));
    log_lik=log_likelihood(X,W,sigma,K);
    lik = log_lik;
    %% Repeat
    for iter = 1:10
        % E-step
        M = W'*W + sigma*eye(K);
        U = chol(M);
        V= inv(U);
        Ezn = {};
        Eznznt = {};
        for i=1:N
            Ezn{i} = (V*V')* W'*X(:,i);
            Eznznt{i} = sigma.*(V*V') + Ezn{i}*Ezn{i}';
        end
        % M-step
        tmp=0;
        tmp1=0;
        
        for i = 1:N
            tmp = tmp + X(:,i)*Ezn{i}';
            tmp1 = tmp1 + Ezn{i}*Ezn{i}';
        end
        W_new = tmp * inv(tmp1 + sigma.*(V*V'));
        sigma_new=0;
        for i =1:N
            sigma_new = sigma_new + (norm(X(:,i))^2 - 2*Ezn{i}'* W_new'*X(:,i) + ...
                trace(Eznznt{i}*W_new'*W_new));
        end
        sigma_new=sigma_new/(N*D);
        %%% Update param
        W = W_new;
        sigma = sigma_new;
        log_lik_new = log_likelihood(X,W,sigma,K);
        lik = [lik,log_lik_new];
    end
    figure,
    plot(lik)    
    project_train_data = W'*X;
    test_x = loadMNISTImages('data/t10k-images-idx3-ubyte')'; 
    test_y = loadMNISTLabels('data/t10k-labels-idx1-ubyte');
    Xt=test_x'-mu*ones(1,10000);
    proj_x_test=W'*Xt;
    % Estimate mean and covariance for each class
    traindata=cell(1,10);
    for j = 1:10
       traindata{j}=project_train_data(:,find(labels == j-1));
    end
    meann=cell(1,10);
    covv=cell(1,10);
    for i =1:10
       meann{i}=mean(traindata{i},2);
       covv{i}=cov(traindata{i}');
    end
    % Score test data
     score=zeros(10000,10);
     for i =1:10
        score(:,i)= mvnpdf(proj_x_test',meann{i}',covv{i});
     end
     [~,result] = max(score,[],2); 
     result=result-1;
    % Compare
     tmp=0;
     compare=result-test_y;
     for i =1:10000
        if compare(i)==0
            tmp=tmp+1;
        end
     end
     accuracy=[accuracy,tmp/10000];
end;