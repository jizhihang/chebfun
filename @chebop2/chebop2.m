classdef chebop2
%CHEBOP2   CHEBOP2 class for representing partial differential operators.
%
% Class used to solve PDEs defined on rectangular domains that have
% unique and globally smooth solutions.
%
% N = CHEBOP2(@(u) op(u)) constructs an operator N representing the
% operator given in @(u)op(u) acting on functions of two variables on
% [-1,1] by [-1,1].
%
% N = CHEBOP2(@(u) op(u), [a b c d]) constructs an operator N acting on
% functions of two variables defined on [a,b] by [c,d].
%
% N = CHEBOP2(@(x,y,u) op(x,y,u),...) constructs a variable coefficient PDE
% operator.
%
% Boundary conditions are imposed via the syntax N.lbc, N.rbc, N.ubc, and
% N.dbc. For example to solve Poisson with Dirichlet conditions try:
%
% Example:
%    N = chebop2(@(u) diff(u,2,1) + diff(u,2,2));
%    N.lbc = 0; N.rbc = 0; N.ubc = 0; N.dbc = 0;
%    u = N \ 1;
%
% For further details about the PDE solver, see: 
% 
% A. Townsend and S. Olver, The automatic solution of partial differential
% equations using a global spectral method, in preparation, 2014.
% 
% Warning: This PDE solver is an experimental new feature. It has not been
% publicly advertised.  
        
% Copyright 2014 by The University of Oxford and The Chebfun2 Developers.
% See http://www.chebfun.org/ for Chebfun information.
    
    %% PROPERTIES.
    properties ( GetAccess = 'public', SetAccess = 'public' )
        
        domain = [];  % Domain of the operator.
        op = [];      % The operator.
        ubc = [];     % Up boundary condition(s).
        lbc = [];     % Left boundary condition(s).
        rbc = [];     % Right boundary condition(s).
        dbc = [];     % Down boundary condition(s).
        dim = [];     % Size of the system (number of eqns).
        scale = [];   % Relative solution scale.
        coeffs = [];  % Matrix storing constant coefficients.
        xorder = 0;   % Diff order in the x-variable.
        yorder = 0;   % Diff order in the y-variable.
        U             %
        S             % Low rank form of the partial differential operator.
        V             %
        
    end
    
    %% CONSTRUCTOR.
    methods
        
        function N = chebop2(varargin)
            % CHEBOP2 CONSTRUCTOR.
            
            % Get CHEBFUN2 preferences.
            prefs = chebfunpref();
            tol = prefs.techPrefs.eps;
            
            % If empty input arguments then return an empty CHEBOP2 object.
            if ( isempty(varargin) )
                return
            end
            
            % What domain is the operator defined on?
            if ( numel(varargin) > 1 )
                ends = varargin{2}; % Second argument should be a domain.
                if ( length(ends) == 4 )
                    % Valid domain?
                    if ( diff(ends(1:2)) > 0 && diff(ends(3:4)) > 0 )  
                        dom = ends;
                    else
                        error('CHEBFUN:CHEBOP2:chebop2:emptyDomain', ...
                            'Empty domain.');
                    end
                else
                    error('CHEBFUN:CHEBOP2:chebop2:badDomain',...
                        'Argument should be a domain given by four doubles.')
                end
            else
                if ( isa(varargin{1}, 'function_handle') )
                    % Pick the default domain.
                    rect1 = [-1, 1];
                    rect2 = [-1, 1];
                    dom = [rect1, rect2];
                elseif ( isa( varargin{1}, 'double') )
                    % Set up identity operator on the domain.
                    N = chebop2(@(u) u, varargin{1});  
                    return
                else
                    error('CHEBFUN:CHEBOP2:chebop2:badArg',...
                        'First argument is not an operator or domain.')
                end
            end

            % First argument in the constructor is the operator. If the 
            % operator is univariate then it's a constant coefficient PDE, 
            % otherwise assume it is a variable coefficient.
            if ( isa(varargin{1},'function_handle') )
                fh = varargin{1};
                
                if ( nargin(fh) == 1 )  % The PDE has constant coefficients.
                                        % Trust that the user has formed the CHEBFUN2 objects 
                    % outside of CHEBOP2.
                    u = adchebfun2(chebfun2(@(x,y) x.*y, dom));
                    v = fh(u);
                    % If the PDO has constant coefficients then convert to 
                    % double:
                    try
                        A = cell2mat(v.jacobian).';
                    catch
                        % PDO has variable coefficients, keep them in a 
                        % cell array:
                        A = v.jacobian;
                    end
                    
                elseif ( nargin(fh) == 2 )
                    error('CHEBFUN:CHEBOP2:chebop2:badOp1', ...
                        'Did you intend to have @(x,y,u)?')
                elseif ( nargin(fh) == 3 )
                    % The coefficients of the PDE are now variable 
                    % coefficient.
                    
                    % Setup a chebfun2 on the right domain
                    u = adchebfun2(chebfun2(@(x,y) x.*y, dom));
                    x = chebfun2(@(x,y) x, dom);
                    y = chebfun2(@(x,y) y, dom);
                    % Apply it to the operator.
                    v = fh(x, y, u);
                    A = v.jacobian;  % Cell array of variable coefficients.
                else
                    error('CHEBFUN:CHEBOP2:chebop2:badOp2',...
                        'Operator should be @(u) or @(x,y,u).')
                end
                
            else
                error('CHEBFUN:CHEBOP2:chebop2:badOp3',...
                    'First argument should be an operator')
            end
            
            % Often the coefficients are obtained with small rounding errors
            % and it is important to remove the very small non-zero ones to
            % have rank(A) correct.
            if ( iscell(A) )
                for jj = size(A, 1)
                    for kk = size(A, 2)
                        if ( isa(A{jj,kk}, 'double') && abs(A{jj,kk}) < 10*tol )
                            A{jj,kk} = 0;
                        end
                    end
                end
            else
                A(abs(A) < 10*tol) = 0;
            end
            
            % Construct CHEBOP2 object. The boundary conditions will be 
            % given later.
            N.domain = dom;
            N.op = fh;
            N.coeffs = A;
            
            % Calculate xorder and yorder of PDE.
            % Find the differential order of the PDE operator.
            if ( iscell(A) )
                xdifforder = size(A, 2) - 1;
                ydifforder = size(A, 1) - 1;
            elseif ( min(size(A)) > 1 )
                xdifforder = find(sum(abs(A), 2) > 100*tol, 1, 'last') - 1;
                ydifforder = find(sum(abs(A)) > 100*tol, 1, 'last' ) - 1;
            else
                if ( size(A, 1) == 1 )
                    ydifforder = length(A) - 1;
                    xdifforder = 0;
                else
                    xdifforder = length(A) - 1;
                    ydifforder = 0;
                end
            end
            N.xorder = xdifforder;
            N.yorder = ydifforder;
            
            % Issue a warning to the user for the first CHEBOP2:
            warning('CHEBFUN:CHEBOP2:chebop2:experimental',...
                ['CHEBOP2 is a new experimental feature.'...
                'It has not been tested to the same extent as other'...
                'parts of the software.']);
            % Turn it off:
            warning('off', 'CHEBFUN:CHEBOP2:chebop2:experimental');
            
        end
        
    end
     
    %% STATIC HIDDEN METHODS.
    methods ( Static = true, Hidden = true )
        
        % Matrix equation solver: AXB^T + CXD^T = E. xsplit, ysplit = 1 if
        % the even and odd modes (coefficients) decouple.
        X = bartelsStewart(A, B, C, D, E, xsplit, ysplit);
        
        % Use automatic differentiation to pull out the coeffs of the
        % operator:
        deriv = chebfun2deriv(op);
        
        % This is used to discretize the linear constrains:
        [bcrow, bcvalue] = constructBC(bcArg, bcpos,...
            een, bcn, dom, scl, order);
        
        % This is used to discretize the PDE:
        [CC, rhs, bb, gg, Px, Py, xsplit, ysplit] =...
            discretize(N, f, m, n, flag);
        
        % Convert all the different user inputs for bc into uniform format:
        bc = createBC(bcArg, ends);
        
        % Method for deciding how to solve the matrix equation:
        X = denseSolve(N, f, m, n);
        
        % Remove trailing coefficients.
        a = truncate(a, tol);
        
    end
    
end
