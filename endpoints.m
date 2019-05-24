function [B2,E2,B1,E1]=endpoints(Er,Zr,ITU,ITR,IZCT)

Le=length(Er);
%% Stage 1
flag=1;
c=1;
B1=1;
while (flag)    
    while (Er(c)<=ITR)
        c=c+1;
    end
    B1=c;
    flag=0;
    for c=B1+1:B1+3
        if c>Le
            break;
        end
        if Er(c)<ITU
            flag=1;            
            break;        
        end
    end
    if flag
        c=B1+1;
    else
        break;
    end
end

%% Stage 2
flag=1;
c=length(Er);
E1=c;
while (flag)    
    while (Er(c)<=ITR)
        c=c-1;
    end
    E1=c;
    flag=0;
    for c=E1-1:-1:E1-3
        if c<1
            break;
        end
        if Er(c)<ITU
            flag=1;            
            break;        
        end
    end
    if flag
        c=E1-1;
    else
        break;
    end
end

%% Stage 3
sumZ=0;
ind=[];
for i=B1:-1:B1-25
    if i<1
        break;
    end

    if Zr(i)>IZCT
        sumZ=sumZ+1;
        ind=[i ind];
    end
end
if sumZ>=4
    B2=ind(1);
else
    B2=B1;
end

%% Stage 4
sumZ=0;
ind=[];
for i=E1:E1+25
    if i>Le
        break;
    end

    if Zr(i)>IZCT
        sumZ=sumZ+1;
        ind=[ind i];
    end
end
if sumZ>=4
    E2=ind(end);
else
    E2=E1;
end

%% Stage 5
i=B2-1;
while (1)
    if i<1
        i=1;
        break;
    end    
    if Er(i)>ITR
        B2=i;
    else
        break;
    end
    i=i-1;
end

i=E2+1;
while(1)
    if i>Le
        i=Le;
        break;
    end    
    if Er(i)>ITR
        E2=i;
    else
        break;
    end
    i=i+1;
end


end