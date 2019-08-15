% ʱ���ѹ� 230.853172 �롣 Aug 15, 2019
clear
clc %%%%%%%
close all
nt=4520;    % number of time steps
eps=.6;     % stability
isnap=20;    % snapshot sampling
load('vp')
v=dataxx;
nx=600;
nx=nx+45*2;
nz=200;
nz=nz+45*2;

vv=zeros(nz,nx);
for ii=1:nz-90
    for jj=1:nx-90
        vv(ii+45,jj+45)=v(ii,jj);
    end
end

for ii=1:nz-90  %%left
    for jj=1:45
        vv(ii+45,jj)=v(ii,1);
    end
end

for ii=1:nz-90  %%right
    for jj=nx-45:nx
        vv(ii+45,jj)=v(ii,end);
    end
end


for ii=1:45  %%top
    for jj=1:nx
        vv(ii,jj)=vv(46,jj);
    end
end

for ii=nz-44:nz  %%bottom
    for jj=1:nx
        vv(ii,jj)=vv(nz-45,jj);
    end
end
vp=vv;

clear vv;
load('vs')
v=dataxx;

vv=zeros(nz,nx);
for ii=1:nz-90
    for jj=1:nx-90
        vv(ii+45,jj+45)=v(ii,jj);
    end
end

for ii=1:nz-90  %%left
    for jj=1:45
        vv(ii+45,jj)=v(ii,1);
    end
end

for ii=1:nz-90  %%right
    for jj=nx-45:nx
        vv(ii+45,jj)=v(ii,end);
    end
end


for ii=1:45  %%top
    for jj=1:nx
        vv(ii,jj)=vv(46,jj);
    end
end

for ii=nz-44:nz  %%bottom
    for jj=1:nx
        vv(ii,jj)=vv(nz-45,jj);
    end
end

vs=vv;

rou=ones(nz,nx);

dx=20;  %calculate space increment
h=dx;
x=(0:(nx-1))*dx;
z=(0:(nz-1))*dx;  % initialize space coordinates
dt=0.001; % calculate time step from stability criterion
tau=dt;


f0=25;
t=(1:nt)*dt;
t0=4/f0;                       % initialize time axis
src=10^2*exp(-f0^2*(t-t0).*(t-t0));              % source time function
src=-diff((src))/dx^2;				% time derivative to obtain gaussian


zs=46;
xs=600-150+25;


seis_recordVx=zeros(nt,nx);
seis_recordVz=zeros(nt,nx);
seis_recordTxx=zeros(nt,nx);
seis_recordTzz=zeros(nt,nx);
seis_recordTxz=zeros(nt,nx);

%  ******************************************************************
%  txz-------------vx
%  |                |
%  |                |
%  |                |
%  |                |
%  |                |
%  vz---------------txx,tzz
% Virieux 1986 Geophysics
xs=floor(nx/2);
zs=46;
tic

dx=h;
dz=h;
% 
% for ii=1:nx
%     kx(ii)=(2*pi/(nx*dx-dx)*(ii-nx/2-1));
% end
% 
% for ii=1:nz
%     kz(ii)=(2*pi/(nz*dz-dz)*(ii-nz/2-1));
% end

kx=linspace(-pi/dx,pi/dx, nx);
kz=linspace(-pi/dz,pi/dz, nz);

kexp=1i*kx.*exp(1i*kx*dx/2);
kexpp=(1i*kz.*exp(1i*kz*dx/2))';

kexpm= 1i*kx.*exp(-1i*kx*dx/2);
kexppm=(1i*(kz.*exp(-1i*kz*dx/2)))';

M1=repmat(kexp,nz,1);
M2=repmat(kexpp,1,nx);
M3=repmat(kexpm,nz,1);
M4=repmat(kexppm,1,nx);
p=zeros([nz nx]); Vx=p; Vz=p;
Txxx=p;
Txzz=p;
Tzzz=p;
Txzx=p;

Txx=p;
Txz=p;
Tzz=p;


Vxx=p;
Vzz=p;
Vxz=p;
Vzx=p;
for it=1:nt-2,
    
    %Txx/x
    Txxx=ifft(ifftshift(M1.*fftshift(fft(Txx,nx,2),2 ),2) ,nx,2);
    
    %Txz/z
    Txzz=ifft(ifftshift(M2.*fftshift(fft(Txz,nz,1),1),1), nz,1);
    
    %Txz/x
    Txzx=ifft(ifftshift(M3.*fftshift(fft(Txz,nx,2) ,2),2) ,nx,2);
    
    %Tzz/z
    Tzzz=ifft(ifftshift(M4.*fftshift(fft(Tzz,nz,1),1),1), nz,1);
    
    Vx=Vx+1./(rou).*dt.*(Txxx+Txzz);
    Vz=Vz+1./(rou).*dt.*(Tzzz+Txzx);
    
    Vx(zs,xs)=Vx(zs,xs)+src(it);
    Vz(zs,xs)=Vz(zs,xs)+src(it);
    [Vx,Vz]=spongeABC(Vx,Vz,nx,nz,45,45,0.009);
    seis_recordVx(it,:)=Vx(zs,:);
    seis_recordVz(it,:)=Vz(zs,:);
    
    Vxx=ifft( ifftshift(M3.*fftshift(fft(Vx,nx,2),2 ),2) ,nx,2);
    Vzz=ifft(ifftshift(M2.*fftshift(fft(Vz,nz,1),1),1), nz,1);
    Vxz=ifft(ifftshift(M4.*fftshift(fft(Vx,nz,1),1),1), nz,1);
    Vzx=ifft( ifftshift(M1.*fftshift(fft(Vz,nx,2),2 ),2) ,nx,2);
    
    Txx=Txx+dt*rou.*(vp.^2.*Vxx+(vp.^2-2*vs.^2).*Vzz);
    Tzz=Tzz+dt*rou.*(vp.^2.*Vzz+(vp.^2-2*vs.^2).*Vxx);
    Txz=Txz+dt*rou.*(vs.^2).*(Vxz+Vzx);
    
    seis_recordTxx(it,:)=Txx(zs,:);
    seis_recordTzz(it,:)=Tzz(zs,:);
    seis_recordTxz(it,:)=Txz(zs,:);
    
    
    if rem(it,isnap)== 0,
        imagesc(x,z,real(Vx)), axis equal
        colormap gray
        xlabel('x'),ylabel('z')
        title(sprintf(' Time step: %i - Max ampl: %g ',it,max(max(Vx))))
        drawnow
    end
    
end

toc
save('KSpaceLayer3.mat')  %kexpp=(1i*kz.*exp(1i*kz*dx/2))';