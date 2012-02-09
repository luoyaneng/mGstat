% fft_ma :
% Call :
%    [out,z,options,logL]=fft_ma_2d(x,y,z,Va,options)
%
%    x: array, ex : x=1:1:80:
%    y: array, ex : y=1:1:50:
%    z: array, ex : y=1:1:30:
%    Va: variogram def, ex : Va="1 Sph (10,.4,30)";
%
%
% "
%   Ravalec, M.L. and Noetinger, B. and Hu, L.Y.},
%   Mathematical Geology 32(6), 2000, pp 701-723
%   The FFT moving average (FFT-MA) generator: An efficient numerical
%   method for generating and conditioning Gaussian simulations
% "
%
% Example:
%  x=[1:1:50];y=1:1:80;z=1:30;
%  Va='1  Sph(10,.25,30)';
%  [out,z]=fft_ma(x,Va); % 1D
%  [out,z]=fft_ma(x,y,Va); % 2D
%  [out,z]=fft_ma(x,y,z,Va); %3D
%
% See also: fft_ma_1d, fft_ma_2d, fft_ma_3d
%
%
% original (FFT_MA) Knud S. Cordua (June 2009)
% Thomas M. Hansen (September, 2009)
% Jan Frydendall (April, 2011) Zero padding

%
function [out,z_rand,options,logL]=fft_ma(x,y,z,Va,options)

if nargin>1,
    if (isstr(y)|isstruct(y))
        Va=y;
        % 1D
        if nargin==3, options=z; else; options.null='';end
        Va=y;
        [out,z_rand,options,logL]=fft_ma_2d(x,Va,options);
        return
    end
end

if nargin>2,
    if (isstr(z)|isstruct(z))
        % 2D 
        if nargin==4,options=Va; else; options.null='';end
        Va=z;
        [out,z_rand,options,logL]=fft_ma_2d(x,y,Va,options);
        return
    end
end

options.null='';
[out,z_rand,options,logL]=fft_ma_3d(x,y,z,Va,options);
out=squeeze(out);
