function [Rob,Cam] = initRayBicam(...
   Rob,Cam,...
   vRay,Obs,yCrit,...
   sMax,...
   alpha,beta,gamma,tau,...
   patchSize,lostRayTh)

% INITRAYBICAM  Initialize ray beyond observability region
%   [ROB,CAM] = INITRAYBICAM(R,C,VR,OB,YC,SM,A,B,G,T,PS,TH)
%   initializes a ray from left camera and FIS-corrects it with
%   the right camera. Input parameters are as follows:
%     R:       Robot structure
%     C:       Cameras structure
%     VR:      virtual ray of e_1 and e_infty
%     OB:      Observations
%     YC:      Critical pixel
%     SM:      Maximum ray depth
%     A,B,G,T: alpha, beta, gamma and tau for FIS algorithm
%     PS,TH:   Patch size and lost-threshold.
%
%   Global Map and Lmk are updated. New robot and cameras
%   structures are returned in ROB, CAM.

% (c) 2006 Joan Sola - LAAS-CNRS

global Lmk



% Get critical point - left camera frame
pCrit = invBiCamPhoto(Cam(1),Cam(2),Obs(1).y,yCrit);

% critical depth
sCrit = pCrit(3);

% Ray initialization beyond critical point
ray          = getFree([Lmk.Ray.used]);
Lmk.Ray(ray) = rayInit(...
   Lmk.Ray(ray),...
   Rob,...
   Cam(1),...
   Obs(1),...
   sCrit,sMax,...
   alpha,beta,gamma,tau,...
   patchSize,...
   lostRayTh);

% Observation on camera 2
Lmk.Ray(ray).Prj(2).y       = Obs(2).y;
Lmk.Ray(ray).Prj(2).matched = 1;
Lmk.Ray(ray).Prj(2).updated = 1;

% Project onto camera 2
Lmk.Ray(ray) = projectRay(...
   Rob,...
   Cam(2),...
   Lmk.Ray(ray),...
   Obs(2).R);

% Complete ray statistics
Lmk.Ray(ray) = uRayInnovation(...
   Lmk.Ray(ray),...
   2,...
   Obs(2).y,...
   Obs(2).R);

% Weight updating and pruning
Lmk.Ray(ray) = updateWeight(Lmk.Ray(ray),2);
Lmk.Ray(ray) = pruneRay(Lmk.Ray(ray));
Lmk.Ray(ray) = pruneTwinPoints(Lmk.Ray(ray));

liberateMap(Lmk.Ray(ray).pruned);

% correct map
[Rob,Cam(2)] = FISUpdate(...
   Rob,...
   Cam(2),...
   Lmk.Ray(ray),...
   Obs(2));