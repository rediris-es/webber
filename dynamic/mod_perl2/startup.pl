
use ModPerl::Registry () ;

use lib qw(/usr/lib/webber/proc  ) ;

use Webber::FilterRaw  ;
use Webber::FilterHTML ;
Webber::FilterRaw::read_webber_conf("/etc/webber/apache-webber.xml") ;
Webber::FilterHTML::read_webber_conf("/etc/webber/apache-webber.xml") ;

1;
