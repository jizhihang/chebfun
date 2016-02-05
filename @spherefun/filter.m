function g = filter( f, dt )
% FILTER     Gaussian filtering on the sphere. 
% 
%  G = FILTER( F ), applies a low-pass filter to F. This is based on
%  Gaussian filtering.  
% 
%  G = FILTER( F, dt ), applies a low-pass filter to F with parameter dt.
%  The default to dt =1e-6, which is equivalent to running the Heat
%  equation for time dt with the initial condition being F. 

if ( nargin < 2 ) 
    dt = 1e-3; 
end
K = sqrt(1/dt)*1i;

% Find the length of f.
[m, n] = length( f ); 

% Solve the Helmholtz equation on the sphere to apply the Gaussian filter. 
% Since, g is expected to smoother than f, and mxn discretization should
% suffice. 
g = spherefun.Helmholtz( -f, K, m, n);

end 