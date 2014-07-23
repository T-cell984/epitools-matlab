function LoadControls(obj,settingsObj)
%LOADCONTROLS Summary of this function goes here
%   Detailed explanation goes here

import javax.*

% Show a JTree in a JScrollpane

root        = javax.swing.tree.DefaultMutableTreeNode('Analysis');
treeModel   = javax.swing.tree.DefaultTreeModel(root);
tree        = javax.swing.JTree(treeModel);

leafIcon            = javax.swing.ImageIcon('./images/bricks.png');
folderIconOpen      = javax.swing.ImageIcon('./images/folder-2.png');
folderIconClosed    = javax.swing.ImageIcon('./images/folder-2.png');

renderer            = javax.swing.tree.DefaultTreeCellRenderer();
renderer.setLeafIcon(leafIcon);
renderer.setClosedIcon(folderIconClosed);
renderer.setOpenIcon(folderIconOpen);

tree.setCellRenderer(renderer);

vec1 = fieldnames(settingsObj.analysis_modules);

for i=1:length(vec1)
    
    Module_Node = javax.swing.tree.DefaultMutableTreeNode(vec1{i});
    %fprintf('%s -', vec1{i});
    vec2 = fieldnames(settingsObj.analysis_modules.(char(vec1{i})));
    if (isempty(vec2) == 0)
        for o=1:length(vec2)
            
            SubModule_Node = javax.swing.tree.DefaultMutableTreeNode(vec2{o});
            %fprintf('%s -', vec2{o});
            classSubTree = class(settingsObj.analysis_modules.(char(vec1{i})).(char(vec2{o})));
            
            switch classSubTree
                %case 'cell'
                    
                    %vec3 = '';

                case 'struct'
                    
                    if(isempty(fieldnames(settingsObj.analysis_modules.(char(vec1{i})).(char(vec2{o}))))==0)
                        
                        vec3 = fieldnames(settingsObj.analysis_modules.(char(vec1{i})).(char(vec2{o})));
                        %if (isempty(vec3) == 0)
                        for u=1:length(vec3)
                            val = settingsObj.analysis_modules.(char(vec1{i})).(char(vec2{o})).(char(vec3{u}));
                            classVal = class(val);
                            switch classVal
                                case 'double'
                                   val = num2str(val); 
                                case 'logical'
                                    
                                    if (val)
                                        val = char('true');
                                    else
                                        val = char('false');
                                    end
                                    
                            end
                            
                            SubModule_Node.add(javax.swing.tree.DefaultMutableTreeNode(sprintf('%s = %s',vec3{u}, val)));
                            
                        end
                        %end    
                    end
                    
            end
            
            Module_Node.add(SubModule_Node);
        end
    end
    
    %Module_Node.add(SubModule_Node); 
    root.add(Module_Node)
end
% A_Node = javax.swing.tree.DefaultMutableTreeNode('Registration');
% B_Node = javax.swing.tree.DefaultMutableTreeNode('Projection');
% C_Node = javax.swing.tree.DefaultMutableTreeNode('Segmentation');
%javax.swing.tree.setIcon(leafIcon2)
% root.add(A_Node)
% root.add(B_Node)
% root.add(C_Node)

% treeView = javax.swing.JScrollPane(tree);
% % Create the HTML viewing pane.
% htmlPane =  javax.swing.JEditorPane();
% htmlPane.setEditable(false);
% %initHelp();
% htmlView = javax.swing.JScrollPane(htmlPane);
% splitPane = javax.swing.JSplitPane(javax.swing.JSplitPane.VERTICAL_SPLIT);
%
% splitPane.setTopComponent(treeView);
% splitPane.setBottomComponent(htmlView);

% for k=1:20
%     root.insert(javax.swing.tree.DefaultMutableTreeNode(sprintf('Item %d',k)), k-1);
% end

scrollpane=javax.swing.JScrollPane();
scrollpane.setViewportView(tree);
scrollpane.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_ALWAYS);
scrollpane.setHorizontalScrollBarPolicy(javax.swing.ScrollPaneConstants.HORIZONTAL_SCROLLBAR_ALWAYS);
scrollpane.setBorder(javax.swing.BorderFactory.createTitledBorder(''));
jcontrol(obj, scrollpane,'Position', [0.0 0.023 0.25 0.915]);



end

