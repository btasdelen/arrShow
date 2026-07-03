function R = mydlg(promt, dlg_title, defAns, pos)
% dialog with working standard keypress functions, e.g. return to accept and escape
% to close.
if nargin < 4
    pos = [500 500 210 90];
end
if nargin < 3
    defAns = '';
end
if nargin < 2
    dlg_title = '';
end
if nargin < 1
    promt = 'Please enter sth.';
end

R = [];

bgColor = java.awt.Color(240/255,240/255,240/255);
fgColor = java.awt.Color(0,0,0);
editBgColor = java.awt.Color(1,1,1);
btnBgColor = java.awt.Color(235/255,235/255,235/255);
prefWidth = max(pos(3), 210);
prefHeight = max(pos(4), 90);

import java.awt.BorderLayout
import java.awt.Dimension
import java.awt.FlowLayout
import javax.swing.BorderFactory
import javax.swing.JButton
import javax.swing.JComponent
import javax.swing.JDialog
import javax.swing.JLabel
import javax.swing.JPanel
import javax.swing.JTextField
import java.awt.event.KeyEvent

dlg = javaObjectEDT(JDialog([], char(dlg_title), true));
dlg.setDefaultCloseOperation(JDialog.DISPOSE_ON_CLOSE);
dlg.setAlwaysOnTop(true);
dlg.setResizable(false);

content = dlg.getContentPane();
content.setLayout(BorderLayout(10,10));
content.setBackground(bgColor);

mainPanel = javaObjectEDT(JPanel(BorderLayout(0,8)));
mainPanel.setBackground(bgColor);
mainPanel.setBorder(BorderFactory.createEmptyBorder(10,10,10,10));

label = javaObjectEDT(JLabel(char(promt)));
label.setForeground(fgColor);
label.setBackground(bgColor);
label.setOpaque(true);
mainPanel.add(label, BorderLayout.NORTH);

editField = javaObjectEDT(JTextField(char(defAns)));
editField.setBackground(editBgColor);
editField.setForeground(fgColor);
editField.setCaretColor(fgColor);
mainPanel.add(editField, BorderLayout.CENTER);

buttonPanel = javaObjectEDT(JPanel(FlowLayout(FlowLayout.RIGHT,5,0)));
buttonPanel.setBackground(bgColor);

okButton = javaObjectEDT(JButton('O.k.'));
okButton.setBackground(btnBgColor);
okButton.setForeground(fgColor);

cancelButton = javaObjectEDT(JButton('Cancel'));
cancelButton.setBackground(btnBgColor);
cancelButton.setForeground(fgColor);

buttonPanel.add(okButton);
buttonPanel.add(cancelButton);

content.add(mainPanel, BorderLayout.CENTER);
content.add(buttonPanel, BorderLayout.SOUTH);

set(handle(okButton,'CallbackProperties'),'ActionPerformedCallback',@okCb);
set(handle(cancelButton,'CallbackProperties'),'ActionPerformedCallback',@cancelCb);
set(handle(editField,'CallbackProperties'),'ActionPerformedCallback',@okCb);
set(handle(editField,'CallbackProperties'),'KeyPressedCallback',@keyPressedCb);

dlg.getRootPane().setDefaultButton(okButton);
dlg.setPreferredSize(Dimension(prefWidth,prefHeight));
dlg.pack();
dlg.setLocation(pos(1),pos(2));
javaMethodEDT('requestFocusInWindow',editField);
dlg.setVisible(true);

    function okCb(~, ~)
        R = char(editField.getText());
        dlg.dispose();
    end

    function cancelCb(~, ~)
        R = [];
        dlg.dispose();
    end

    function keyPressedCb(~, evnt)
        if evnt.getKeyCode() == KeyEvent.VK_ESCAPE
            cancelCb();
        end
    end
end
