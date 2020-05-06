function idx = findresultindex(resultofinterest,version,result_tagtitle)
% resultofinterest = string
% version  = number
% result_tagtitle = cell array
fun = @(A,B)cellfun(@isequal,A,B);
R = {resultofinterest,version};
C = result_tagtitle;
idx = cellfun(@(C)all(fun(R,C)),num2cell(C,2));