! Copyright 2017 Yoshihiro Tanaka
! Licensed under the Apache License, Version 2.0 (the "License");
! you may not use this file except in compliance with the License.
! You may obtain a copy of the License at
! 
!   http://www.apache.org/licenses/LICENSE-2.0
! 
! Unless required by applicable law or agreed to in writing, software
! distributed under the License is distributed on an "AS IS" BASIS,
! WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
! See the License for the specific language governing permissions and
! limitations under the License.
! 
! Author: Yoshihiro Tanaka <contact@cordea.jp>
! date  : 2017-01-28

USING: system kernel io command-line namespaces strings
http http.client io.encodings.utf8 io.files
locals accessors json.reader assocs prettyprint
formatting sequences combinators io.encodings.string ;
IN: telping

<PRIVATE

CONSTANT: config-path "<config.json path>"
CONSTANT: base-url "https://api.twilio.com/2010-04-01/Accounts/%s/Calls.json"

TUPLE: config
    { from string read-only }
    { sid string read-only }
    { url string read-only }
    { token string read-only } ;

C: <config> config

: basic-auth-header ( config -- basic )
    [ sid>> ] [ token>> ] bi basic-auth ;

:: set ( hash value key -- )
    value key hash set-at ;

: post-data ( to config -- post-data )
    H{ }
    {
        [
            swap
            [ from>> "From" set ]
            [ url>> "Url" set ] 2bi
        ]
        [ swap "To" set ]
        [ "GET" "Method" set ]
        [ ]
    } cleave ;

: url ( config -- url )
    sid>> base-url sprintf ;

:: request ( to config -- header )
    to config post-data
    config url
    <post-request>
    config basic-auth-header
    "Authorization" set-header ;

: request-call ( to config -- response )
    request http-request drop ;

: parse-config ( path -- config )
    utf8 file-lines concat json>
    {
        [ "from" swap at ]
        [ "sid" swap at ]
        [ "url" swap at ]
        [ "token" swap at ]
    } cleave
    <config> ;

PRIVATE>

: run ( -- )
    command-line get [
        nl
    ] [
        first
        config-path parse-config
        request-call body>> utf8 decode
        json> "sid" swap at [
            0 exit
        ] [
            1 exit
        ] if
    ] if-empty ;

MAIN: run
