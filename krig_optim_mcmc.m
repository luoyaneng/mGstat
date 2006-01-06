% krig_optim_mcmc
% CALL : 
%   [V_new,be_acc,L_acc,par2,nugfrac_acc,V_acc]=krig_optim_mcmc(pos_known,val_known,V,options)
%
function [V_new,be_acc,L_acc,par2,nugfrac_acc,V_acc]=krig_optim_mcmc(pos_known,val_known,V,options);

V_new=V;

if isstr(V),
  V=deformat_variogram(V);
end 

options.isorange=1;

if isfield(options,'max_range')
  max_range=options.max_range;
else
  max_range=20*std(pos_known);
end

if isfield(options,'step_range')
  step_range=options.step_range;
else
  step_range=std(pos_known);
end

if isfield(options,'step_nugfrac')
  step_nugfrac=options.step_nugfrac;
else
  step_nugfrac=.1;
end

if isfield(options,'annealing')
  annealing=options.annealing;
else
  annealing=0;
end

if isfield(options,'descent')
  descent=options.descent;
else
  descent=0;
end

if isfield(options,'gvar');
  gvar=options.gvar;
else
  gvar=var(val_known);
end


if isfield(options,'maxit');
  maxit=options.maxit;
else
  maxit=1000;
end


ndim=size(pos_known,2);

options.dummy='';

nnug=13;
nugarr=linspace(0,1,nnug);nugarr(1)=.01;

std_known=std(pos_known);
mean_known=mean(pos_known);


% A PRIORI 
na=25;
for idim=1:ndim
  narr{idim}=na;
  arr{idim}=linspace(0,2*std_known(idim),narr{idim});
  arr{idim}(1)=0.01;
end

V_init=V;
V_old=V;
%[d_est,d_var,be_init,d_diff,L_init]=gstat_krig_blinderror(pos_known,val_known,pos_known,V_init,options);
[d_est,d_var,be_init,d_diff,L_init]=krig_blinderror(pos_known,val_known,pos_known,V_init,options);

be_old=be_init;
L_old=1.0001*L_init;
L_arr=[];
L_min=L_init;
L_new=L_init;
range_min=0.001;

nacc=0;
for i=1:maxit

  % Simulated Annealing
  if annealing==1,
    T=exp(-(i-1)/1000);
    options.T=T;
  end

  % PERTURB MODEL
  V_new = V_old;

  % PERTURB RANGE
  V_new(2).par2=V_new(2).par2 + randn(size(step_range)).*step_range;

  % PERTURB NUGGET FRACTION
  nugfrac=V_new(1).par1./gvar;
  nugfrac=nugfrac+randn(1).*step_nugfrac;
  V_new(1).par1=gvar.*nugfrac;
  V_new(2).par1=gvar.*(1-nugfrac);

  % TEST FOR BOUNDS 
  compL=1;
  if ~isempty(find(V_new(2).par2<=0)), compL=0; end 
  for idim=1:ndim
    if ~isempty(find(V_new(2).par2(idim)>=max_range(idim))), 
      compL=0;
    end
  end
%  disp(compL)

  if ((nugfrac<0)|(nugfrac>1))
    compL=0;
  end
%  disp(compL)
%  disp(format_variogram(V_new))
  
  if compL==1
    try
      %[d1,d2,be_new,d_diff,L_new]=gstat_krig_blinderror(pos_known,val_known,pos_known,V_new,options);
      [d1,d2,be_new,d_diff,L_new]=krig_blinderror(pos_known,val_known,pos_known,V_new,options);
    catch
      %keyboard
    end
    
  else
    %L_new=-1e-45;
  end
  
  
  L_min=min([L_min L_new]);
  
  %Pacc=min([(L_new-L_min)/(L_old-L_min),1]);
  Pacc=min([(L_new)/(L_old),1]);

  if compL==0
    Pacc=0;
  end
  
  if descent==1
    % ONLY ACCEPT IMPROVEMENETS
    Prand=1;
  else
    Prand=rand(1);
    end
  
  if Pacc>=Prand
%  if Pacc==1  % ONLY ACCPET IMPROVEMENTS
    
    V_old=V_new;
    L_old=L_new;
    be_old=be_new;
    
    nacc=nacc+1;
    
    par2(nacc,:)=V_new(2).par2;
    
    L_acc(nacc) = L_new;
    be_acc(nacc) = be_new;
    V_acc{nacc} = V_new; 
    nugfrac_acc(nacc) = nugfrac; 

    
    doPlot=1;
    if ((doPlot==1)&(nacc>10));
      subplot(2,1,1)
      plotyy(1:nacc,L_acc,1:nacc,-be_acc);
      
      if size(par2,2)==1
        subplot(2,3,4)
        %plot(par2(:,1),L_acc,'k.')
        [ax,h1,h2]=plotyy(par2(:,1),L_acc,par2(:,1),-be_acc);
        set(h1,'LineStyle','none')
        set(h2,'LineStyle','none')
        set(h1,'Marker','.')
        set(h2,'Marker','.')
        set(h1,'color',[0 0 1])
        set(h2,'color',[1 0 0])
        set(get(ax(1),'Ylabel'),'String','L')
        set(get(ax(2),'Ylabel'),'String','-be')

        xlabel('Range');ylabel('L')
        subplot(2,3,5)
        scatter(par2(:,1),nugfrac_acc,20,L_acc,'filled')
        xlabel('Range');ylabel('Nugget Fraction');title('L')
        subplot(2,3,6)
        scatter(par2(:,1),nugfrac_acc,20,-be_acc,'filled')
        xlabel('Range');ylabel('Nugget Fraction');title('BE')
        drawnow;
      elseif size(par2,2)==2
        subplot(2,3,4)
        scatter(par2(:,1),par2(:,2),22,L_acc,'filled')
        xlabel('Range 1');ylabel('Range 2');title('Likelihood')
        %colorbar
        subplot(2,3,5)
        scatter(par2(:,1),par2(:,2),22,-be_acc,'filled')
        xlabel('Range 1');ylabel('Range 2');title('-be')
        %colorbar
        subplot(2,3,6)
        scatter3(par2(:,1),par2(:,2),nugfrac_acc,20,L_acc,'filled');
        xlabel('Range 1');ylabel('Range 2');zlabel('Nugget Fraction');title('Likelihood')
        drawnow;
      elseif size(par2,2)==3
        subplot(2,3,4)
        scatter3(par2(:,1),par2(:,2),par2(:,3),22,L_acc,'filled')
      end
    end
    V_old=V_new;
    L_old=L_new;
    disp(sprintf('%3d --OK-- L = %6.3g  , PA=%4.2g Prand=%4.2g : %s',i,L_new,Pacc,Prand,format_variogram(V_new)))
    disp(sprintf('nugfrac=%5.4g  Accept rate = %4.2f%%',nugfrac,100.*nacc./i))
  else
    %disp(sprintf('%3d ------ L = %6.3g  , PA=%4.2g Prand=%4.2g : %s',i,L_new,Pacc,Prand,format_variogram(V_new)))
  end

  
end