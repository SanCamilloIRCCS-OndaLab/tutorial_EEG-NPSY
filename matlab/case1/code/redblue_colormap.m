function cmap = redblue_colormap()
  % A simple diverging blue-white-red colormap (matplotlib's RdBu_r,
  % approximated), matching the Python/R correlation heatmaps. MATLAB
  % ships no identical built-in diverging colormap.
  n = 128;
  bottom = [linspace(0.02, 1, n)', linspace(0.19, 1, n)', linspace(0.49, 1, n)'];
  top = [linspace(1, 0.70, n)', linspace(1, 0.09, n)', linspace(1, 0.17, n)'];
  cmap = [bottom; top];
end
