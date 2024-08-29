function distance = calcDistance(data,detAlg)

NormConstA1 = detAlg.NormConstA1;
NormConstA2 = detAlg.NormConstA2;
NormConstA3 = detAlg.NormConstA3;
NormConstA4 = detAlg.NormConstA4;
NormConstB1 = detAlg.NormConstB1;
NormConstB2 = detAlg.NormConstB2;
NormConstB3 = detAlg.NormConstB3;
NormConstB4 = detAlg.NormConstB4;
W1 = detAlg.W1;
W2 = detAlg.W2;
W3 = detAlg.W3;
W4 = detAlg.W4;
b = detAlg.b;

if size(data,2) == 2
    
    X(:,1) = (data(:,1)-NormConstA1)*NormConstB1;
    X(:,2) = (data(:,2)-NormConstA2)*NormConstB2;
    
    distance = - 1 * (sum( [X(:,1) * W1 , X(:,2) * W2],2) - b); % calculation in Activa
    
elseif size(data,2) == 3
    
    X(:,1) = (data(:,1)-NormConstA1)*NormConstB1;
    X(:,2) = (data(:,2)-NormConstA2)*NormConstB2;
    X(:,3) = (data(:,3)-NormConstA3)*NormConstB3;
    
    distance = - 1 * (sum( [X(:,1) * W1 , X(:,2) * W2, X(:,3)*W3] ,2) - b); % calculation in Activa
elseif size(data,2) == 4
    
    X(:,1) = (data(:,1)-NormConstA1)*NormConstB1;
    X(:,2) = (data(:,2)-NormConstA2)*NormConstB2;
    X(:,3) = (data(:,3)-NormConstA3)*NormConstB3;
    X(:,4) = (data(:,4)-NormConstA4)*NormConstB4;
    
    distance = - 1 * (sum( [X(:,1) * W1 , X(:,2) * W2, X(:,3)*W3, X(:,4)*W4] ,2) - b); % calculation in Activa
    
end

end


