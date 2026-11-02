function runDirectory = RUN_PROJECT()
% One command: seven BUILD -> freeze -> three TEST -> videos -> augmentation.
root = fileparts(mfilename('fullpath')); addpath(fullfile(root,'matlab'));
C = PROJECT_CONFIG();
runDirectory = mil_run(root,C,'');
end
