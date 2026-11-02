function ids=mil_display_indices(X,bins)
% Min/max envelope indices for plotting only. Numerical scoring is never thinned.
N=size(X,1);if N<=2*bins,ids=(1:N)';return;end
edges=round(linspace(1,N+1,bins+1));ids=zeros(2*bins*size(X,2)+2,1);n=2;ids(1:2)=[1 N];
for k=1:bins
 ix=edges(k):edges(k+1)-1;
 for j=1:size(X,2)
  [~,a]=min(X(ix,j));[~,b]=max(X(ix,j));ids(n+1:n+2)=[ix(a) ix(b)];n=n+2;
 end
end
ids=unique(ids(1:n));
end
