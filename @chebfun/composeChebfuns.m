function h = composeChebfuns(f, g, pref)
%COMPOSECHEBFUNS   Chebfun composition.
%   COMPOSECHEBFUNS(F, G) returns the composition of the CHEBFUN objects F and
%   G, G(F). The range of F must be in the domain of G or else an error is
%   thrown. An equivalent syntax is G(F).
%
%   COMPOSECHEBFUN(F, G, PREF) uses the CHEBFUN preferences contained in the
%   preference structure PREF.
%
%   Note 1: If the location of required breakpoints in the output are known in
%   advance, they should be applied to F and/or G using RESTRICT() before the
%   call to COMPOSE().
%
%   Note 2: Any higher-order impulse/delta function data in F and/or G is
%   ignored by COMPOSECHEBFUNS().
%
%   Example:
%           f = chebfun(@(x) asin(.99*x)/asin(.99));
%           g = chebfun(@(x) 1./(1+100*x.^2));
%           h = compose(f, g);
%
% See also COMPOSE.

% Copyright 2013 by The University of Oxford and The Chebfun Developers.
% See http://www.chebfun.org for Chebfun information.

% Deal with the trivial empty case:
if ( isempty(f) || isempty(g) )
    h = chebfun();
    return
end

% Obtain preferences:
if ( nargin < 3 )
    pref = chebfun.pref();
else
    pref = chebfun.pref(pref);
end

% If G is a function handle, we can simply call COMPOSE():
if ( ~isa(g, 'chebfun') )
    % Call COMPOSE():
    h = compose(f, g, pref);
    return
end

%% ERROR CHECKING:

if ( ~isa(f, 'chebfun') )
    error('CHEBFUN:compose:NotAChebfun', ...
        'Cannot compose a function handle and CHEBFUN in this way.');
end

if ( xor(f.isTransposed, g.isTransposed) )
    error('CHEBFUN:composeChebfuns:trans', ...
        'Cannot compose a row CHEBFUN with a column CHEBFUN.');
end

isTransposed = f.isTransposed;
if ( isTransposed )
    % Make everything a column CHEBFUN for now:
    f.isTransposed = 0;
    g.isTransposed = 0;
    % [TODO]: Add this once TRANSPOSE() is implemented.
%     f = f.';
%     g = g.';
end

if ( (size(f, 2) > 1) && (size(g, 2) > 1) )
     error('CHEBFUN:composeChebfuns:trans', ...
        'Cannot compose two array-valued CHEBFUN objects.');
end

% f must be a real-valued function:
if ( ~isreal(f) )
    error('CHEBFUN:compose:complex', 'F must be real valued to construct G(F).')
%     warning('CHEBFUN:compose:complex', 'F SHOULD be real valued to construct G(F).');
end

% [TODO]: Requires MINANDMAX().
% % Get epslevels and set a tolerance:
% tol = 10*max(vscale(f).*epslevel(f), vscale(g).*epslevel(g));
% hsf = hscale(f); 
% % Find the range of F:
% mmF = minandmax(f);
% minF = min(mmF(:));
% maxF = max(mmF(:));
% % Range of f must be in the domain of g:
% if ( g.domain(1) > minF + tol*hsf || g.domain(end) < maxF - tol*hsf )
%     error('CHEBFUN:compose:domain', ...
%         'Range of F, [%g, %g], must be in the domain of G, [%g, %g].', ...
%         minF, maxF, g.domain(1), g.domain(end))
% end

% Delta functions:
if ( (size(f.impulses, 3) > 1) || (size(g.impulses, 3) > 1) )
    warning('CHEBFUN:compose:imps',  ...
        'Composition does not handle impulses / delta functions.')
end

%% Locate breakpoints in G:

% If g has breakpoints, find the corresponding x-points in the domain of f:
newDom = f.domain;
if ( numel(g.domain) > 2 )
    gDom = g.domain(2:end-1);
    for k = 1:length(gDom)
        % [TODO]: This requires @CHEBFUN/MINUS.
%         r = roots(f - gDom(k));
%         newDom = [newDom, r(:).']; %#ok<AGROW>
    end
end
newDom = unique(sort(newDom));

% Restrict f to the new domain:
f = restrict(f, newDom);

%% Call COMPOSE():

% Call compose:
h = compose(f, @(f) feval(g, f), pref);

% Fix impulse values:
h.impulses(:,:,1) = feval(g, feval(f, h.domain.'));

if ( isTransposed )
    h.isTransposed = 1;
    % [TODO]: Add this once TRANSPOSE() is implemented.
%     h = h.';
end

end
