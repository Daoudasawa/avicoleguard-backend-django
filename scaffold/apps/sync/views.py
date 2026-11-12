from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from dateutil.parser import parse as parse_date
from .services import get_pull_data, process_push_data

class SyncPullView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        last_sync = request.query_params.get("last_sync")
        if last_sync:
            try:
                last_sync = parse_date(last_sync)
            except ValueError:
                return Response({"error": "Invalid date format"}, status=status.HTTP_400_BAD_REQUEST)
                
        data = get_pull_data(request.user, last_sync_timestamp=last_sync)
        return Response(data)

class SyncPushView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        device_id = request.headers.get("X-Device-ID", "unknown")
        
        try:
            sync_log = process_push_data(request.user, request.data, device_id=device_id)
            return Response({
                "status": sync_log.status,
                "push_count": sync_log.push_count,
                "errors": sync_log.errors
            })
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)
