$(document).ready(function() {
    const $messages = $('#chatMessages');
    const $input = $('#messageInput');
    const $sendBtn = $('#sendButton');
    const $typing = $('#typingIndicator');
    const $uploadBtn = $('#uploadButton');

    let jsonData = [];

    function scrollToBottom() {
        $messages.scrollTop($messages[0].scrollHeight);
    }

    function addMessage(text, sender, references = null) {
        let referencesHtml = '';
        
        if (references && references.length > 0) {
            referencesHtml = '<div class="email-references"><div class="references-title">Referenced Emails</div>';
            references.forEach(ref => {
                referencesHtml += `
                    <div class="email-reference">
                        <div class="email-subject">${ref.subject || 'No Subject'}</div>
                        <div class="email-meta">
                            <div class="email-sender">${ref.sender || 'Unknown'}</div>
                            <div class="email-date">${ref.date || 'N/A'}</div>
                        </div>
                    </div>
                `;
            });
            referencesHtml += '</div>';
        }

        const messageHtml = `
            <div class="message ${sender}">
                <div>
                    <div class="message-label">${sender === 'user' ? 'You' : 'Assistant'}</div>
                    <div class="message-content">
                        ${text}
                        ${referencesHtml}
                    </div>
                </div>
            </div>
        `;
        $typing.before(messageHtml);
        scrollToBottom();
    }

    function showError(message) {
        const errorHtml = `<div class="error-message">${message}</div>`;
        $typing.before(errorHtml);
        setTimeout(() => {
            $('.error-message').fadeOut(300, function() {
                $(this).remove();
            });
        }, 5000);
        scrollToBottom();
    }

    function sendMessage() {
        const message = $input.val().trim();
        
        if (message === '') return;

        addMessage(message, 'user');
        $input.val('');
        $sendBtn.prop('disabled', true);
        $typing.show();
        scrollToBottom();

        $.ajax({
            url: 'http://localhost:8000/walker/ask_email',
            method: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({
                query: message,       // send the user’s text
                raw_emails: jsonData  // keep the email data too
            }),
            timeout: 300000,
            success: function(response) {
                $typing.hide();
                const reply = response.reports[0].response || 'Error.';
                const references = response.references || null;
                addMessage(reply, 'assistant', references);
                $sendBtn.prop('disabled', false);
            },
            error: function(xhr, status, error) {
                $typing.hide();
                let errorMsg = 'Failed to connect to the email assistant. ';
                
                if (status === 'timeout') {
                    errorMsg += 'Request timed out.';
                } else if (xhr.status === 0) {
                    errorMsg += 'Please check if the server is running.';
                } else {
                    errorMsg += `Error: ${error}`;
                }
                
                showError(errorMsg);
                $sendBtn.prop('disabled', false);
            }
        });
    }

    $sendBtn.click(sendMessage);

    $input.keypress(function(e) {
        if (e.which === 13) {
            sendMessage();
        }
    });

    $input.focus();

    $uploadBtn.click(function() {
        const fileInput = $('<input type="file" accept=".json" style="display: none;">');
        $('body').append(fileInput);

        fileInput.trigger('click');

        fileInput.change(function() {
            const file = this.files[0];
            if (!file) return;

            addMessage(`Uploading and processing ${file.name}...`, 'user');
            $uploadBtn.prop('disabled', true);
            $typing.show();
            scrollToBottom();

            const reader = new FileReader();
            reader.onload = function(e) {
                try {
                    jsonData = JSON.parse(e.target.result); // assign to global variable

                    if (!Array.isArray(jsonData)) {
                        throw new Error("Invalid JSON format. Expected an array of email objects.");
                    }

                    $.ajax({
                        url: 'http://localhost:8000/walker/upload_emails',
                        method: 'POST',
                        contentType: 'application/json',
                        data: JSON.stringify({
                            raw_emails: jsonData
                        }),
                        timeout: 60000,
                        success: function(response) {
                            $typing.hide();
                            const message = response.message || `Uploaded ${jsonData.length} emails successfully!`;
                            addMessage(message, 'assistant');
                            $uploadBtn.prop('disabled', false);
                        },
                        error: function(xhr, status, error) {
                            $typing.hide();
                            let errorMsg = 'Failed to upload emails. ';
                            if (status === 'timeout') {
                                errorMsg += 'Upload timed out.';
                            } else if (xhr.status === 0) {
                                errorMsg += 'Please check if the server is running.';
                            } else {
                                errorMsg += `Error: ${error}`;
                            }
                            showError(errorMsg);
                            $uploadBtn.prop('disabled', false);
                        }
                    });

                } catch (err) {
                    $typing.hide();
                    showError(`Error reading JSON: ${err.message}`);
                    $uploadBtn.prop('disabled', false);
                }
            };
            reader.readAsText(file);
            fileInput.remove();
        });
    });
});