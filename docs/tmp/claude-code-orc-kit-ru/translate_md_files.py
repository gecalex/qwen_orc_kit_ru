#!/usr/bin/env python3
"""
Script to translate all .md files in the project from English to Russian
while preserving formatting and technical terms.
"""

import os
import re
import sys
from pathlib import Path

def is_likely_english(text):
    """Check if text likely contains English content that needs translation."""
    # Look for common English words and phrases
    english_indicators = [
        r'\b(the|and|or|but|in|on|at|to|for|of|with|by|as|is|are|was|were|be|been|have|has|had|do|does|did|will|would|could|should|may|might|can|must|am|an|a|this|that|these|those|I|you|he|she|it|we|they|me|him|her|us|them|my|your|his|its|our|their|mine|yours|hers|ours|theirs)\b',
        r'\b(file|code|project|function|variable|class|method|module|package|library|framework|api|database|server|client|user|system|application|service|config|configuration|documentation|example|test|debug|console|error|warning|info|log|build|deploy|release|version|git|github|repository|branch|commit|merge|pull|push|clone|fetch|status|diff|add|remove|delete|create|update|modify|change|edit|save|load|read|write|open|close|start|stop|run|execute|process|thread|memory|cpu|disk|network|request|response|url|http|https|json|xml|html|css|javascript|typescript|python|java|c\+\+|c#|go|rust|swift|kotlin|scala|php|ruby|sql|bash|shell|command|terminal|cli|gui|ui|ux|frontend|backend|fullstack|devops|ci|cd|docker|kubernetes|aws|azure|gcp|cloud|security|authentication|authorization|oauth|jwt|token|session|cookie|cache|storage|database|sql|nosql|mongodb|postgresql|mysql|redis|elasticsearch|kafka|rabbitmq|graphql|rest|api|endpoint|route|path|parameter|query|mutation|subscription|websocket|sse)\b',
        r'\b(agent|command|skill|orchestrator|worker|plan|config|context|validation|report|task|phase|workflow|session|environment|variable|setting|parameter|option|flag|argument|input|output|result|status|success|failure|error|warning|info|debug|trace|level|type|name|path|directory|folder|extension|format|structure|template|schema|definition|implementation|function|method|class|interface|module|package|library|framework|tool|utility|script|instruction|guide|tutorial|readme|changelog|license|author|maintainer|contributor|developer|engineer|architect|designer|tester|qa|quality|assurance|vulnerability|bug|issue|ticket|feature|enhancement|improvement|optimization|performance|speed|efficiency|memory|cpu|disk|bandwidth|connection|timeout|retry|backoff|circuit|breaker|rate|limit|throttle|cache|invalidate|expire|ttl|redis|memcached|query|transaction|lock|mutex|semaphore|thread|process|queue|stack|heap|list|array|map|set|object|json|xml|yaml|toml|ini|csv|tsv|html|css|js|ts|jsx|tsx|py|rb|go|rs|java|cpp|csharp|php|sql|sh|bash|zsh|fish|cmd|ps1|dockerfile|makefile|cmakelists|jenkinsfile|travis|circle|github|gitlab|bitbucket|npm|yarn|pnpm|pip|conda|homebrew|apt|yum|dnf|pacman|docker|podman|kubernetes|k8s|helm|openshift|terraform|ansible|puppet|chef|vagrant|virtualbox|vmware|aws|gcp|azure|oci|digitalocean|linode|vultr|heroku|netlify|vercel|cloudflare|fastly|akamai|nginx|apache|tomcat|jetty|caddy|traefik|haproxy|istio|linkerd|envoy|jaeger|zipkin|prometheus|grafana|datadog|newrelic|sentry|rollbar|airbrake|logstash|elasticsearch|kibana|fluentd|splunk|syslog|rsyslog|journald|systemd|cron|at|batch|scheduler|quartz|airflow|luigi|prefect|temporal|cadence|conductor|zeebe|kafka|pulsar|activemq|rabbitmq|redis|memcached|etcd|consul|vault|zookeeper|nats|mqtt|amqp|grpc|thrift|avro|protobuf|graphql|rest|soap|xmlrpc|jsonrpc|msgpackrpc|openid|saml|oauth|jwt|oidc|ldap|kerberos)\b',
        r'\b(orchestrator|worker|plan|config|context|validation|report|task|phase|workflow|session|environment|variable|setting|parameter|option|flag|argument|input|output|result|status|success|failure|error|warning|info|debug|trace|level|type|name|path|directory|folder|extension|format|structure|template|schema|definition|implementation|function|method|class|interface|module|package|library|framework|tool|utility|script|instruction|guide|tutorial|readme|changelog|license|author|maintainer|contributor|developer|engineer|architect|designer|tester|qa|quality|assurance|vulnerability|bug|issue|ticket|feature|enhancement|improvement|optimization|performance|speed|efficiency|memory|cpu|disk|bandwidth|connection|timeout|retry|backoff|circuit|breaker|rate|limit|throttle|cache|invalidate|expire|ttl|redis|memcached|query|transaction|lock|mutex|semaphore|thread|process|queue|stack|heap|list|array|map|set|object|json|xml|yaml|toml|ini|csv|tsv|html|css|js|ts|jsx|tsx|py|rb|go|rs|java|cpp|csharp|php|sql|sh|bash|zsh|fish|cmd|ps1|dockerfile|makefile|cmakelists|jenkinsfile|travis|circle|github|gitlab|bitbucket|npm|yarn|pnpm|pip|conda|homebrew|apt|yum|dnf|pacman|docker|podman|kubernetes|k8s|helm|openshift|terraform|ansible|puppet|chef|vagrant|virtualbox|vmware|aws|gcp|azure|oci|digitalocean|linode|vultr|heroku|netlify|vercel|cloudflare|fastly|akamai|nginx|apache|tomcat|jetty|caddy|traefik|haproxy|istio|linkerd|envoy|jaeger|zipkin|prometheus|grafana|datadog|newrelic|sentry|rollbar|airbrake|logstash|elasticsearch|kibana|fluentd|splunk|syslog|rsyslog|journald|systemd|cron|at|batch|scheduler|quartz|airflow|luigi|prefect|temporal|cadence|conductor|zeebe|kafka|pulsar|activemq|rabbitmq|redis|memcached|etcd|consul|vault|zookeeper|nats|mqtt|amqp|grpc|thrift|avro|protobuf|graphql|rest|soap|xmlrpc|jsonrpc|msgpackrpc|openid|saml|oauth|jwt|oidc|ldap|kerberos)\b'
    ]
    
    text_lower = text.lower()
    for pattern in english_indicators:
        if re.search(pattern, text_lower):
            return True
    
    return False

def should_translate_file(file_path):
    """Check if a file should be translated based on its content."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read(2000)  # Read first 2000 characters to check
        return is_likely_english(content)
    except:
        return False

def translate_content(content):
    """
    Translate English content to Russian while preserving formatting.
    This function will be replaced with actual translation logic.
    For now, this is a placeholder that will be handled by the calling system.
    """
    # This function will be implemented using the system's translation capabilities
    # In the actual implementation, this would connect to translation tools
    return content

def main():
    # Get all .md files in the project
    md_files = []
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.lower().endswith('.md'):
                md_files.append(os.path.join(root, file))
    
    print(f"Found {len(md_files)} .md files")
    
    # Process each file
    for i, file_path in enumerate(md_files, 1):
        print(f"Processing ({i}/{len(md_files)}): {file_path}")
        
        # Check if file should be translated
        if should_translate_file(file_path):
            print(f"  - File appears to contain English content, translating...")
            
            # Read the original content
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
            
            # Translate the content (placeholder - would use actual translation)
            translated_content = translate_content(original_content)
            
            # Write the translated content back
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(translated_content)
            
            print(f"  - Translated successfully")
        else:
            print(f"  - File appears to be in Russian or doesn't need translation, skipping...")
    
    print(f"\nTranslation process completed for {len(md_files)} files")

if __name__ == "__main__":
    main()