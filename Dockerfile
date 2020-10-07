FROM docker.io/bitnami/moodle:3

RUN apt update && \
    apt install --no-install-recommends -qqy git && \
    apt -qqy autoremove --purge && \
    apt -qqy clean && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/trampgeek/moodle-qtype_coderunner.git /opt/bitnami/moodle/question/type/coderunner \
    && chown -R daemon /opt/bitnami/moodle/question/type/coderunner

RUN git clone https://github.com/trampgeek/moodle-qbehaviour_adaptive_adapted_for_coderunner.git /opt/bitnami/moodle/question/behaviour/adaptive_adapted_for_coderunner \
    && chown -R daemon /opt/bitnami/moodle/question/behaviour/adaptive_adapted_for_coderunner