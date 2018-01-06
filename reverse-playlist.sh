#
# This script reverses the tracks in a playlist.
# If the playlist is from another user then a new playlist is created.
#
# This is very convenient for top-lists which are usually sorted starting with number 1.
# Currently (Jan 2018) the Spotify clients do not enable you to play a playlist in reversed order.
#
# Just invoke this script without parameters to get the usage.
#
#
# Fitzgerald Jan 2018
#

# This scripts has a few dependencies on some (standard Linux) commands:
# base64
# jq
# curl
# nc
# tac

#
# The script will check for these dependencies.
#

#
# The source for this script is on Github: https://github.com/FitzgeraldKrudde/spotify-reverse-playlist
#

#
# Spotify application ID (reverse-playlist)
#
CLIENT_ID="07bf716bf6c547a989dfbc5f987784f4"
CLIENT_SECRET="53f765611b5d4ec4b4dba497f6fce262"

#
# base64 clientid/clientsecret
#
b64_client_id_secret=$(echo -ne "${CLIENT_ID}":"${CLIENT_SECRET}" | base64 --wrap=0)

#
# listen port for nc callback
#
PORT=8888
#
# redirect URL after providing access
#
REDIRECT_URI="http://localhost:${PORT}"

#
# Spotify REST stuff
#
SPOTIFY_API_TOKEN="https://accounts.spotify.com/api/token"
SPOTIFY_API_AUTHORIZE="https://accounts.spotify.com/authorize/"
SPOTIFY_API_BASE_URL="https://api.spotify.com/v1"
SPOTIFY_API_ME_URL="${SPOTIFY_API_BASE_URL}/me"
SPOTIFY_API_SCOPES=$(echo "playlist-read-private playlist-modify-public playlist-modify-private user-read-private" | tr ' ' '%' | sed s/%/%20/g)
SPOTIFY_ACCEPT_HEADER="Accept: application/json"
SPOTIFY_CONTENT_TYPE_HEADER="Content-Type: application/json"
CURL_OPTIONS="--silent"
#CURL_OPTIONS=""

#
# functions
#
usage() {
	echo "usage: $0 <playlist-id> [playlist-userid] [new-playlist-name] [new-playlist-description]"
	echo ""
	echo "This script reverses the tracks in a playlist."
	echo "The only required parameter is playlist-id."
	echo "Per default a playlist in your account is then used."
	echo ""
	echo "If you want to use a playlist of another user then the parameter playlist-userid is needed."
	echo "Then a new playlist (with the tracks reversed) will be created in your account"
	echo "For the new playlist the default name/description is:"
	echo "name: '<current-name> reversed'"
	echo "description: '<current-description> (reversed)'"
	echo "If you want to use something else then provide the parameters."
	echo ""
	echo "The easiest way to find the playlist-id and the playlist-userid:"
	echo "use the Spotify web player (https://open.spotify.com) and go to the playlist."
	echo "For example: https://open.spotify.com/user/spotify_netherlands/playlist/7DSznpxTfYe9h2S6lxLXar"
	echo ""
	echo "playlist-id -> 7DSznpxTfYe9h2S6lxLXar"
	echo "playlist-userid -> spotify_netherlands"
}

checkForErrorInResponse() {
	local response=$1
	local error=$(echo ${response} | jq -r '.error')
	if [[ "${error}" != "null" ]]
	then
		echo "failed with the following error:"
		echo "${error}"
		echo "exiting.."
		exit 1
	fi
}

checkForBinary() {
	local cmd=$1
	if ! which $cmd > /dev/null
	then
		echo "missing binary: $cmd"
		echo "exiting..."
		exit 2
	fi
}

#
# /functions
#

#
# start script
#

#
# check for prerequisite binaries
#
checkForBinary base64
checkForBinary jq
checkForBinary curl
checkForBinary nc
checkForBinary tac

#
# check for required parameter source_playlist_id
#
if [[ "${#}" -lt "1" ]]
then
	usage
	exit 1
else
	source_playlist_id="${1}"
	echo "source_playlist_id: $source_playlist_id"
fi

#
# read optional parameters
# 
if [[ -n $2 ]]
then
	source_playlist_userid="${2}"
	echo "source_playlist_userid: $source_playlist_userid"
else
	reversing_own_playlist="true"
	echo "reversing own playlist"
fi
if [[ -n $3 ]]
then
	destination_playlist_name="${3}"
	echo "destination_playlist_name: $destination_playlist_name"
fi
if [[ -n $4 ]]
then
	destination_playlist_description="${4}"
	echo "destination_playlist_description: $destination_playlist_description"
fi

#
# send the user to the Spotify URL for authorization
#
authorization_endpoint="${SPOTIFY_API_AUTHORIZE}?response_type=code&client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SPOTIFY_API_SCOPES}"
echo "Go to this URL to authorize this script: $authorization_endpoint"
echo "After authorization this script will pickup the authorization code"
response=$(echo -e 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 0\r\nAccess-Control-Allow-Origin:*\r\nConnection: Close\r\n\r\nDone!\r\n\r\n\r\n' | nc -l -p "${PORT}")
authorization_code=$(echo "${response}" | grep GET | cut --delimiter=' ' -f 2 | cut --delimiter='=' -f 2)
echo "Got authorization code: ${authorization_code}"

#
# get a Spotify access token for this authorization code
#
response=$(curl ${CURL_OPTIONS} --header "Content-Type:application/x-www-form-urlencoded" --header "Authorization: Basic $b64_client_id_secret" --data "grant_type=authorization_code&code=${authorization_code}&redirect_uri=${REDIRECT_URI}" ${SPOTIFY_API_TOKEN})
checkForErrorInResponse "${response}"
spotify_access_token=$(echo "${response}" | jq -r '.access_token')

#
# define the Spotify authorization header
#
spotify_authorization_header="Authorization: Bearer ${spotify_access_token}"

#
# get info for the current Spotify user
#
response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${SPOTIFY_API_ME_URL}")
checkForErrorInResponse "${response}"
current_spotify_user=$(echo ${response} | jq -r '.id')
echo "current_spotify_user: ${current_spotify_user}"

#
# if no userid has been provided, use the current Spotify user
#
if [[ -z ${source_playlist_userid} ]]
then
	source_playlist_userid=${current_spotify_user}
fi

#
#
# get the playlist info
#
response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${SPOTIFY_API_BASE_URL}/users/${source_playlist_userid}/playlists/${source_playlist_id}")
checkForErrorInResponse "${response}"
playlist_api_url=$(echo ${response} | jq -r '.tracks.href')
source_playlist_url=$(echo ${response} | jq -r '.external_urls.spotify')

# set name of the new playlist based on the retrieved playlist (if a name has not been provided on the commandline)
#
if [[ -z ${destination_playlist_name} ]]
then
	playlist_name=$(echo ${response} | jq -r '.name')
	destination_playlist_name="${playlist_name} reversed"
fi

#
# set description of the new playlist based on the retrieved playlist (if a name has not been provided on the commandline)
#
if [[ -z ${destination_playlist_description} ]]
then
	playlist_description=$(echo ${response} | jq -r '.description')
	destination_playlist_description="${playlist_description} reversed"
fi

#
# get the tracks of the playlist (first 100)
#
response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${playlist_api_url}")
checkForErrorInResponse "${response}"
all_tracks=$(echo ${response} | jq -r '.items[].track.uri')
next=$(echo ${response} | jq -r '.next')
echo -e "#retrieved tracks: $(wc -w <<< ${all_tracks})\c"

##
# if there are more tracks (next uri != null), retrieve them
#
while [ "${next}" != "null" ]
do
	response=$(curl ${CURL_OPTIONS} --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" "${next}")
	checkForErrorInResponse "${response}"
	tracks=$(echo ${response} | jq -r '.items[].track.uri')
	all_tracks="${all_tracks}
${tracks}"
	next=$(echo ${response} | jq -r '.next')
	echo -e " $(wc -w <<< ${all_tracks})\c"
done

#
# reverse the tracks
#
tracks_reversed=$(echo ${all_tracks} | xargs --no-run-if-empty --max-args=1 | tac)
echo ""
echo "#tracks_reversed: $(wc -w <<< ${tracks_reversed})"

#
# check if we:
#	- reverse a playlist of our own: empty the current playlist (and add the reversed tracks)
# 	- reverse a playlist of another user: create a new playlist (and add the reversed tracks)
#
if [[ "${reversing_own_playlist}" == "true" ]]
then
	destination_playlist_id="${source_playlist_id}"
	#
	# empty the current playlist (and add the reversed tracks)
	#
	post_body="$(jq --null-input '{uris:[]}' )"
	response=$(curl ${CURL_OPTIONS} --request PUT "${SPOTIFY_API_BASE_URL}/users/${current_spotify_user}/playlists/${source_playlist_id}/tracks" --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" --header "${SPOTIFY_CONTENT_TYPE_HEADER}" --data "${post_body}")
	checkForErrorInResponse "${response}"
	destination_playlist_url="${source_playlist_url}"
else
	#
	# create a new playlist
	#
	post_body=$(jq --null-input --arg name "${destination_playlist_name}" --arg description "${destination_playlist_description}" '{name:$name, description:$description, public:true}')
	response=$(curl ${CURL_OPTIONS} --request POST "${SPOTIFY_API_BASE_URL}/users/${current_spotify_user}/playlists" --header "${SPOTIFY_ACCEPT_HEADER}" --header "${spotify_authorization_header}" --header "${SPOTIFY_CONTENT_TYPE_HEADER}" --data "${post_body}")
	checkForErrorInResponse "${response}"
	destination_playlist_id=$(echo ${response} | jq -r '.id')
	destination_playlist_url=$(echo ${response} | jq -r '.external_urls.spotify')
	echo "Created a new playlist"
fi

#
# add all the tracks to the (new) playlist (max 100 per request)
#
echo -e "Adding tracks to the new playlist: \c"
echo ${tracks_reversed} | xargs --no-run-if-empty --max-args=100 | while read line
do
	post_body=$(echo "\"${line}\"" | jq 'split(" ") as $tracks | {uris:$tracks}')
	response=$(curl ${CURL_OPTIONS} --request POST "${SPOTIFY_API_BASE_URL}/users/${current_spotify_user}/playlists/${destination_playlist_id}/tracks" --header "${SPOTIFY_ACCEPT_HEADER}" --header "${SPOTIFY_CONTENT_TYPE_HEADER}" --header "${spotify_authorization_header}" --data "${post_body}") 
	checkForErrorInResponse "${response}"
	echo -e ".\c"
done
echo ""

#
# finished
#
echo "Finished succesfully. URL of the (new) playlist: ${destination_playlist_url}"


