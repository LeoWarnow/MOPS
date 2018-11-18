function [xres,fres,k] = ps_standard(problem,beta,epsilon,b,r,a_start,a_lim)
%PS_ADAPT (Non-adaptive) Pascoletti Serafini Method for m=2
%   Computes optimal solutions of a given function f by using the
%   Pascoletti Serafini Scalarization Method

% Load the function parameters
[n,m,fun,x0,Aineq,bineq,Aeq,beq,lb,ub,nonlcon,options] = problem();

% Check for solver options
if isempty(options)
    % If there are no options set, at least fall back to these here
	options = optimset('Display','none'); 
end

%Initialize internal parameters and output
steps = floor(1/epsilon);
xres = zeros(n,m);
fres = zeros(m,m);

% Autocompute parameter a if not given
if isempty(a_start)
	E = eye(m,m);
    a = zeros(m,m);
	for i=1:m
        [xtmp,~] = fmincon(@(x) E(i,:)*fun(x),x0,Aineq,bineq,Aeq,beq,lb,ub,nonlcon,options);
        ftmp = fun(xtmp);
        a(:,i) = ftmp-((b'*ftmp-beta)/(b'*r)).*r;
        fres(:,i) = ftmp;
        xres(:,i) = xtmp;
	end
    a_lim = a(:,2);
    a_start = a(:,1);
end

% Set range for parameter a and initialize it
v = a_lim-a_start;
a = a_start;

% Main part of scalarization
% New constraints
if ~isempty(Aineq)
    l = size(Aineq,1);
    Aineq = [Aineq,zeros(l,1)];
end
if ~isempty(Aeq)
    l = size(Aeq,1);
    Aeq = [Aeq,zeros(l,1)];
end
lb = [lb;-Inf];
ub = [ub;Inf];
function [ps_c,ps_ceq] = ps_nonlcon(x)
    x_part = x(1:n);
    [c,ps_ceq] = nonlcon(x_part);
    c_new = -a-x(n+1).*r+fun(x_part);
    ps_c = [c;c_new];
end

% Optimization problem for scalarization
for k=2:steps
    a = a+epsilon.*v;
    [x] = fmincon(@(x) x(n+1),[x0;0],Aineq,bineq,Aeq,beq,lb,ub,@(x) ps_nonlcon(x),options);
    x_sol = x(1:n);
    xres = [xres,x_sol];
    fres = [fres,fun(x_sol)];
end
k=k+1;
end
