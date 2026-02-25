# Zeek Configuration for VCD-01 Security Monitoring
# This file configures Zeek to monitor suspicious IPs

@load base/frameworks/notice
@load base/protocols/http
@load base/protocols/ssh
@load base/protocols/ssl

# Define suspicious IP set
global suspicious_ips: set[addr] = {
    185.191.171.3,
    192.0.78.24,
    192.0.78.25,
    52.230.152.148,
    34.223.12.181,
    66.249.66.75
};

# Enhanced logging for suspicious IPs
redef Log::default_rotation_interval = 1 hr;
redef Log::default_rotation_postprocessor_cmd = "gzip";

# Connection tracking
event connection_established(c: connection)
{
    if (c$id$orig_h in suspicious_ips || c$id$resp_h in suspicious_ips)
    {
        local msg = fmt("Suspicious IP connection: %s -> %s:%s", 
                       c$id$orig_h, c$id$resp_h, c$id$resp_p);
        
        NOTICE([$note=SuspiciousIP_Connection,
                $conn=c,
                $msg=msg,
                $identifier=cat(c$id$orig_h, c$id$resp_h)]);
        
        # Log to custom file
        print fmt("[%s] %s", network_time(), msg) >> "/var/log/zeek/suspicious-ips.log";
    }
}

# HTTP request monitoring
event http_request(c: connection, method: string, original_URI: string,
                   unescaped_URI: string, version: string)
{
    if (c$id$orig_h in suspicious_ips)
    {
        local msg = fmt("Suspicious HTTP request: %s %s from %s", 
                       method, original_URI, c$id$orig_h);
        
        NOTICE([$note=SuspiciousIP_HTTP,
                $conn=c,
                $msg=msg,
                $identifier=cat(c$id$orig_h, original_URI)]);
        
        # Check for attack patterns
        if (/SELECT|UNION|DROP|INSERT/ in original_URI)
        {
            NOTICE([$note=SQLi_Attempt,
                    $conn=c,
                    $msg=fmt("Possible SQLi from %s: %s", c$id$orig_h, original_URI),
                    $identifier=cat(c$id$orig_h, original_URI)]);
        }
        
        if (/\.\.\/|\.\.\\/ in original_URI)
        {
            NOTICE([$note=LFI_Attempt,
                    $conn=c,
                    $msg=fmt("Possible LFI from %s: %s", c$id$orig_h, original_URI),
                    $identifier=cat(c$id$orig_h, original_URI)]);
        }
    }
}

# SSH connection monitoring
event ssh_auth_attempted(c: connection, authenticated: bool)
{
    if (c$id$orig_h in suspicious_ips)
    {
        local msg = fmt("SSH auth attempt from suspicious IP %s: %s", 
                       c$id$orig_h, authenticated ? "SUCCESS" : "FAILED");
        
        NOTICE([$note=SuspiciousIP_SSH,
                $conn=c,
                $msg=msg,
                $identifier=cat(c$id$orig_h)]);
    }
}

# SSL/TLS monitoring
event ssl_established(c: connection)
{
    if (c$id$orig_h in suspicious_ips || c$id$resp_h in suspicious_ips)
    {
        NOTICE([$note=SuspiciousIP_SSL,
                $conn=c,
                $msg=fmt("SSL connection with suspicious IP: %s <-> %s", 
                        c$id$orig_h, c$id$resp_h),
                $identifier=cat(c$id$orig_h, c$id$resp_h)]);
    }
}

# Elasticsearch integration
event zeek_init()
{
    print "Zeek VCD-01 Security Monitoring Started";
    print fmt("Monitoring %d suspicious IPs", |suspicious_ips|);
}

# Custom notice types
redef enum Notice::Type += {
    SuspiciousIP_Connection,
    SuspiciousIP_HTTP,
    SuspiciousIP_SSH,
    SuspiciousIP_SSL,
    SQLi_Attempt,
    LFI_Attempt
};

# Send notices to Elasticsearch (requires elasticsearch plugin)
#redef Notice::policy += {
#    [$action = Notice::ACTION_LOG,
#     $result = Notice::ACTION_ELASTICSEARCH]
#};
